
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QtQuick/QQuickView>
#include <QQmlContext>

#ifdef Q_OS_LINUX
#include <pthread.h>
#include <signal.h>
#endif

#include "videoitem.h"
#include "gamelibrarymodel.h"
#include "librarydbmanager.h"
#include "phoenixwindow.h"
#include "phoenixlibrary.h"
#include "phoenixlibraryhelper.h"
#include "cacheimage.h"
#include "phoenixglobals.h"
#include "utilities.h"
#include "usernotifications.h"

int main( int argc, char *argv[] ) {
#ifdef Q_OS_LINUX
    // When using QAudioOutput on linux/ALSA, we need to
    // block SIGIO on all threads except the audio thread
    sigset_t set;
    sigemptyset( &set );
    sigaddset( &set, SIGIO );
    pthread_sigmask( SIG_BLOCK, &set, nullptr );
#endif

    qSetMessagePattern( "[%{if-debug}D%{endif}%{if-warning}W%{endif}"
                        "%{if-critical}C%{endif}%{if-fatal}F%{endif}]"
                        "%{if-category} [%{category}]:%{endif} %{message}" );

    QGuiApplication a( argc, argv );
    a.setApplicationName( "Phoenix" );
    a.setApplicationVersion( PHOENIX_VERSION );
    a.setOrganizationName( "Phoenix" );
    //    a.setOrganizationDomain("phoenix-emu.org");
    QSettings settings;


    qmlRegisterType<PhoenixWindow>( "phoenix.window", 1, 0, "PhoenixWindow" );
    qmlRegisterType<CachedImage>( "phoenix.image", 1, 0, "CachedImage" );
    qmlRegisterType<VideoItem>( "phoenix.video", 1, 0, "VideoItem" );
    qmlRegisterType<GameLibraryModel>();
    qmlRegisterType<PhoenixLibrary>( "phoenix.library", 1, 0, "PhoenixLibrary" );
    qmlRegisterType<InputDeviceMapping>();
    qmlRegisterType<InputDevice>();
    qRegisterMetaType<retro_device_id>( "retro_device_id" );
    qRegisterMetaType<int16_t>( "int16_t" );
    qRegisterMetaType<InputDeviceEvent *>();

    QQmlApplicationEngine engine;
    // first, set the context properties
    QQmlContext *rctx = engine.rootContext();

    phxGlobals.setOfflineStoragePath( engine.offlineStoragePath() + "/" );

    input_manager.setContext( rctx );


    rctx->setContextProperty( "phoenixGlobals", &phxGlobals );
    rctx->setContextProperty( "phoenixLibraryHelper", &phoenixLibraryHelper );
    rctx->setContextProperty( "userNotifications", &userNotifications );

    // then, load qml and display the window
    engine.load( QUrl( "qrc:/qml/main.qml" ) );
    QObject *topLevel = engine.rootObjects().value( 0 );
    PhoenixWindow *window = qobject_cast<PhoenixWindow *>( topLevel );
    window->show();

    input_manager.scanDevicesAsync();

    return a.exec();
}
