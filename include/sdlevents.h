
#ifndef SDLEVENTS_H
#define SDLEVENTS_H

#include <functional>
#include <mutex>
#include <QObject>
#include <QTimer>
#include <QThread>
#include <QList>

#ifdef __unix__

#include <SDL2/SDL.h>

#elif

#include <SDL.h>

#endif

#include "inputdevice.h"


/* The SDLEvents class is sued to start SDL's event loop, binding it to a different thread,
 * and setting up callbacks to the appropriate InputDevice.
 */
class SDLEvents : public QObject {
        Q_OBJECT
    public:
        SDLEvents();
        virtual ~SDLEvents();

        typedef std::function<bool( const SDL_Event * )> EventCallback;

        void registerCallback( EventCallback *cb ) {
            QMutexLocker lock( &event_callbacks_mutex );
            event_callbacks.append( cb );
        }

        void removeCallback( EventCallback *cb ) {
            QMutexLocker lock( &event_callbacks_mutex );
            event_callbacks.removeOne( cb );
        }

        // locks the SDL event loop.
        // for when functions outside of the SDL thread want to call SDL functions
        std::unique_lock<QMutex> lockSDL() {
            return std::unique_lock<QMutex>( sdl_mutex );
        }

    protected slots:
        void pollSDL();
        void threadStarted();
        void threadFinished();

    private:
        QTimer polltimer;
        QThread thread;

        // buffer used to temporarily store events we got from SDL
        SDL_Event *event_list;

        QList<EventCallback *> event_callbacks;
        QMutex event_callbacks_mutex;
        QMutex sdl_mutex;
};

#endif
