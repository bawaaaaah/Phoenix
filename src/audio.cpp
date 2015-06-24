
#include "audio.h"

Audio::Audio( QObject *parent )
    : QObject( parent ),
      isCoreRunning( false ),
      audioOut( nullptr ),
      audioOutIODev( nullptr ),
      audioBuf( new AudioBuffer ) {

    Q_CHECK_PTR( audioBuf );

    resamplerState = nullptr;

    // We need to send this signal to ourselves
    connect( this, &Audio::signalFormatChanged, this, &Audio::slotHandleFormatChanged );

    outputDataFloat = nullptr;
    outputDataShort = nullptr;
}

Audio::~Audio() {
    if( audioOut ) {
        delete audioOut;
    }

    if( audioOutIODev ) {
        delete audioOutIODev;
    }

    if( outputDataFloat ) {
        delete outputDataFloat;
    }

    if( outputDataShort ) {
        delete outputDataShort;
    }
}

AudioBuffer *Audio::getAudioBuf() const {
    return audioBuf.get();
}

void Audio::setInFormat( QAudioFormat newInFormat ) {

    qCDebug( phxAudio, "setInFormat(%iHz %ibits)", newInFormat.sampleRate(), newInFormat.sampleSize() );

    QAudioDeviceInfo info( QAudioDeviceInfo::defaultOutputDevice() );

    audioFormatIn = newInFormat;
    audioFormatOut = info.nearestFormat( newInFormat ); // try using the nearest supported format

    if( audioFormatOut.sampleRate() < audioFormatIn.sampleRate() ) {
        // If that got us a format with a worse sample rate, use preferred format
        audioFormatOut = info.preferredFormat();
    }

    sampleRateRatio = ( double )audioFormatOut.sampleRate()  / audioFormatIn.sampleRate();

    qCDebug( phxAudio ) << "audioFormatIn" << audioFormatIn;
    qCDebug( phxAudio ) << "audioFormatOut" << audioFormatOut;
    qCDebug( phxAudio ) << "sampleRateRatio" << sampleRateRatio;
    qCDebug( phxAudio, "Using nearest format supported by sound card: %iHz %ibits",
             audioFormatOut.sampleRate(), audioFormatOut.sampleSize() );

    emit signalFormatChanged();

}

void Audio::slotHandleFormatChanged() {
    if( audioOut ) {
        audioOut->stop();
        delete audioOut;
    }

    audioOut = new QAudioOutput( audioFormatOut );
    Q_CHECK_PTR( audioOut );
    //audioOut->moveToThread( &audioThread );

    connect( audioOut, &QAudioOutput::stateChanged, this, &Audio::slotStateChanged );
    audioOutIODev = audioOut->start();

    if( !isCoreRunning ) {
        audioOut->suspend();
    }

    //audioOutIODev->moveToThread( &audioThread );

    // This is where the amount of time that passes between audio updates is set
    // At timer intervals this low on most OSes the jitter is quite significant
    // Try to grab data from the input buffer at least every frame
    // qint64 durationInMs = audioFormatOut.durationForBytes( audioOut->periodSize() * 1.0 ) / 1000;
    qint64 durationInMs = 16;
    qCDebug( phxAudio ) << "Timer interval set to" << durationInMs << "ms, Period size" << audioOut->periodSize() << "bytes, buffer size" << audioOut->bufferSize() << "bytes";


    if( resamplerState ) {
        src_delete( resamplerState );
    }

    int errorCode;
    resamplerState = src_new( SRC_SINC_BEST_QUALITY, 2, &errorCode );

    if( !resamplerState ) {
        qCWarning( phxAudio ) << "libresample could not init: " << src_strerror( errorCode ) ;
    }

    // Now that the IO devices are properly set up,
    // allocate space for buffers that'll hold up to their hardware couterpart's size in data
    auto outputDataSamples = audioOut->bufferSize() * 2;
    qCDebug( phxAudio ) << "Allocated" << outputDataSamples << "for conversion.";

    if( outputDataFloat ) {
        delete outputDataFloat;
    }

    if( outputDataShort ) {
        delete outputDataShort;
    }

    outputDataFloat = new float[outputDataSamples];
    outputDataShort = new short[outputDataSamples];
}

void Audio::slotThreadStarted() {
    if( !audioFormatIn.isValid() ) {
        // We don't have a valid audio format yet...
        qCDebug( phxAudio ) << "audioFormatIn is not valid";
        return;
    }

    slotHandleFormatChanged();
}

void Audio::slotHandlePeriodTimer() {

    // Handle the situation where there is no device to output to
    if( !audioOutIODev ) {
        qCDebug( phxAudio ) << "Audio device was not found, attempting reset...";
        emit signalFormatChanged();
        return;
    }

    // Handle the situation where there is an error opening the audio device
    if( audioOut->error() == QAudio::OpenError ) {
        qWarning( phxAudio ) << "QAudio::OpenError, attempting reset...";
        emit signalFormatChanged();
    }

    auto samplesPerFrame = 2;

    // Max number of bytes/frames we can write to the output
    auto outputBytesFree = audioOut->bytesFree();
    auto outputFramesFree = audioFormatOut.framesForBytes( outputBytesFree );
    // auto outputSamplesFree = outputFramesFree * samplesPerFrame;

    // If output buffer is somehow full despite DRC, empty it
    if( !outputBytesFree ) {
        qWarning( phxAudio ) << "Output buffer full, resetting...";
        emit signalFormatChanged();
        return;
    }

    // Compute the exact number of bytes to read from the circular buffer to
    // produce outputBytesFree bytes of output; Taking resampling and DRC into account
    double maxDeviation = 0.005;
    auto outputBufferTargetPoint = audioOut->bufferSize() / 2;
    auto distanceFromTarget = outputBufferTargetPoint - ( audioOut->bufferSize() - outputBytesFree );
    double direction = ( double )distanceFromTarget / outputBufferTargetPoint;
    double adjust = 1.0 + maxDeviation * direction;
    double adjustedSampleRateRatio = sampleRateRatio * adjust;
    auto audioFormatTemp = audioFormatIn;
    audioFormatTemp.setSampleRate( audioFormatOut.sampleRate() * adjustedSampleRateRatio );
    auto inputBytesToRead = audioFormatTemp.bytesForDuration( audioFormatOut.durationForBytes( distanceFromTarget < 0 ? 0 : distanceFromTarget ) );

    // Read the input data
    auto inputBytesRead = audioBuf->read( inputDataChar, inputBytesToRead );
    auto inputFramesRead = audioFormatIn.framesForBytes( inputBytesRead );
    auto inputSamplesRead = inputFramesRead * samplesPerFrame;

    // libsamplerate works in floats, must convert to floats for processing
    src_short_to_float_array( ( short * )inputDataChar, inputDataFloat, inputSamplesRead );

    // Set up a struct containing parameters for the resampler
    SRC_DATA srcData;
    srcData.data_in = inputDataFloat;
    srcData.data_out = outputDataFloat;
    srcData.end_of_input = 0;
    srcData.input_frames = inputFramesRead;
    srcData.output_frames = outputFramesFree; // Max size
    srcData.src_ratio = adjustedSampleRateRatio;

    // Perform resample
    src_set_ratio( resamplerState, adjustedSampleRateRatio );
    auto errorCode = src_process( resamplerState, &srcData );

    if( errorCode ) {
        qCWarning( phxAudio ) << "libresample error: " << src_strerror( errorCode ) ;
    }

    auto outputFramesConverted = srcData.output_frames_gen;
    auto outputBytesConverted = audioFormatOut.bytesForFrames( outputFramesConverted );
    auto outputSamplesConverted = outputFramesConverted * samplesPerFrame;

    // Convert float data back to shorts
    src_float_to_short_array( outputDataFloat, outputDataShort, outputSamplesConverted );

    int outputBytesWritten = audioOutIODev->write( ( char * ) outputDataShort, outputBytesConverted );
    Q_UNUSED( outputBytesWritten );

    /*
    qCDebug( phxAudio ) << "Input is" << ( audioBuf->size() * 100 / audioFormatIn.bytesForFrames( 4096 ) ) << "% full, output is"
                        << ( ( ( double )( audioOut->bufferSize() - outputBytesFree ) / audioOut->bufferSize() ) * 100 )  << "% full ; DRC:" << adjust
                        << ";" << inputBytesToRead << audioFormatIn.bytesForDuration( audioFormatOut.durationForBytes( outputBytesFree ) ) << sampleRateRatio << adjustedSampleRateRatio;
    qCDebug( phxAudio ) << "\tInput: needed" << inputBytesToRead << "bytes, read" << inputBytesRead << "bytes";
    qCDebug( phxAudio ) << "\tOutput: needed" << distanceFromTarget << "bytes, wrote" << outputBytesWritten << "bytes";
    qCDebug( phxAudio ) << "\toutputBytesFree =" << outputBytesFree << "outputBufferTargetPoint =" << outputBufferTargetPoint << "distanceFromTarget =" << distanceFromTarget;
    qCDebug( phxAudio ) << "Input: needed" << audioFormatIn.framesForBytes( inputBytesToRead ) << "frames, read" << audioFormatIn.framesForBytes( inputBytesRead ) << "frames";
    qCDebug( phxAudio ) << "Output: needed" << audioFormatOut.framesForBytes( outputBytesToWrite ) << "frames, wrote" << audioFormatOut.framesForBytes( outputBytesWritten ) << "frames";
    */

}

void Audio::slotRunChanged( bool _isCoreRunning ) {
    isCoreRunning = _isCoreRunning;

    if( !audioOut ) {
        return;
    }

    if( !isCoreRunning ) {
        if( audioOut->state() != QAudio::SuspendedState ) {
            qCDebug( phxAudio ) << "Paused";
            audioOut->suspend();
            emit signalStopTimer();
        }
    } else {
        if( audioOut->state() != QAudio::ActiveState ) {
            qCDebug( phxAudio ) << "Started";
            audioOut->resume();
            emit signalStartTimer();
        }
    }
}

void Audio::slotStateChanged( QAudio::State s ) {
    if( s == QAudio::IdleState && audioOut->error() == QAudio::UnderrunError ) {
        qWarning( phxAudio ) << "audioOut underrun";
        audioOutIODev = audioOut->start();
    }

    if( s != QAudio::IdleState && s != QAudio::ActiveState ) {
        qCDebug( phxAudio ) << "State changed:" << s;
    }
}

void Audio::slotSetVolume( qreal level ) {
    if( audioOut ) {
        audioOut->setVolume( level );
    }
}


