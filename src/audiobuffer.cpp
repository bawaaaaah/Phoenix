
#include <audiobuffer.h>


AudioBuffer::AudioBuffer(size_t size)
                        : m_head(0),
                          m_tail(0),
                          m_size(size)
{
    m_buffer = new char[m_size];
    deviation = 0.002;
}

AudioBuffer::~AudioBuffer()
{
    delete [] m_buffer;
}

size_t AudioBuffer::write(const char *data, size_t size)
{
    size_t wrote = 0;
    size_t head, tail, nextHead;


    int half_size = size / 2;
    //qreal direction = (qreal)delta_mid / mid_point;
    //qreal adjust = 1.0; //+ control_delta * direction;

    //qCDebug(phxAudio) << "deviation: " << size * deviation  << " normal: " << size;

    while(wrote < size) {
        head = m_head.load(std::memory_order_relaxed);
        nextHead = next(head);
        tail = m_tail.load(std::memory_order_acquire);
        if (nextHead == tail) {
            // buffer is full. let's just clear it.
            // It probably means the core produces frames too fast (not
            // clocked right) or audio backend stopped reading frames.
            // In the first case, it might cause audio to skip a bit.
            qCDebug(phxAudio, "Buffer full, dropping samples");
            clear();
        }

        int avail = (size - wrote);
        int delta_mid = avail - half_size;
        int direction = (qreal)delta_mid / half_size;

            qreal rate_control_delta = ( (size - (2*wrote) ) / size) * deviation;
            //size *= 1.0 + (rate_control_delta * direction);
            size *= (1.0 + (rate_control_delta * direction));
            //qCDebug(phxAudio) << size;
            //if (rate_control_delta > 0) {
            //}
        //}


            //qCDebug(phxAudio) << size;
        m_buffer[head] = data[wrote++];
        m_head.store(nextHead, std::memory_order_release);

    }

    return wrote;
}

size_t AudioBuffer::read(char *data, size_t size)
{
    size_t read = 0;
    size_t head, tail;
    while(read < size) {
        tail = m_tail.load(std::memory_order_relaxed);
        head = m_head.load(std::memory_order_acquire);
        if (tail == head) {
            break;
        }
        data[read++] = m_buffer[tail];
        m_tail.store(next(tail), std::memory_order_release);
    }

    return read;
}

size_t AudioBuffer::size_impl(size_t tail, size_t head) const
{
    if(head < tail) {
        return head + (m_size - tail);
    } else {
        return head - tail;
    }
}

size_t AudioBuffer::size() const
{
    size_t head = m_head.load(std::memory_order_relaxed);
    size_t tail = m_tail.load(std::memory_order_relaxed);
    return size_impl(tail, head);
}

void AudioBuffer::clear()
{
    m_head.store(m_tail.load(std::memory_order_relaxed), std::memory_order_relaxed);
}
