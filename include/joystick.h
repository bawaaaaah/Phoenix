
#ifndef JOYSTICK_H
#define JOYSTICK_H

#include <memory>
#ifdef __unix__

#include <SDL2/SDL.h>

#elif

#include <SDL.h>

#endif

#include "inputdevice.h"
#include "inputdevicemapping.h"
#include "sdlevents.h"

/* The Joystick class is an InputDevice that represents one controller or joystick.
 *
 * This class could exist inside of the InputManager's InputDevice list as long as any
 * controllers or joysticks are connected to the computer.
 */

class Joystick : public InputDevice {
    public:
        Joystick( InputDeviceMapping *mapping );
        virtual ~Joystick();
        void setDeadZone( int threashHold );
        int deadZone() const;


        // enumerate plugged-in devices
        static QVariantList enumerateDevices();

        class Mapping : public InputDeviceMapping {
            public:
                Mapping() : joystick_guid() {};

                virtual InputDeviceEvent *eventFromString( QString ) override;

                virtual bool populateFromSettings( QSettings &settings ) override;
                virtual bool populateFromDict( QVariantMap deviceinfo ) override;

                // return true if joystick with the given guid
                // is handled by this mapping
                bool matchJoystick( const SDL_JoystickGUID &guid ) const;

            public slots:
                virtual QVariant setMappingOnInput( retro_device_id id, QJSValue cb ) override;
                virtual void cancelMappingOnInput( QVariant cancelInfo ) override;

            private:
                SDL_JoystickGUID joystick_guid;

                // only used by setMappingOnInput helper function
                std::unique_ptr<Joystick> joystick;
        };

    private:
        std::shared_ptr<SDLEvents> events;

        Mapping *m_mapping;
        int m_deadzone;

        bool handleSDLEvent( const SDL_Event *event );
        SDLEvents::EventCallback callback;

        SDL_Joystick *joystick;
        SDL_GameController *controller;
        bool device_attached;

        bool deviceAdded( const SDL_Event *event );
        bool deviceRemoved( const SDL_Event *event );

        bool attachJoystick( int which );
        bool attachGameController( int which );

        bool controllerButtonChanged( const SDL_Event *event );
        bool controllerAxisChanged( const SDL_Event *event );

        // convenience functions to check that an event matches the current joystick/controller
        template <typename SDLEventType> bool ControllerMatchEvent( const SDLEventType &event );
        template <typename SDLEventType> bool JoystickMatchEvent( const SDLEventType &event );
};

template <typename SDLEventType>
inline bool Joystick::ControllerMatchEvent( const SDLEventType &event ) {
    auto joyid = SDL_JoystickInstanceID( SDL_GameControllerGetJoystick( controller ) );
    return controller != nullptr && event.which == joyid;
}

template <typename SDLEventType>
inline bool Joystick::JoystickMatchEvent( const SDLEventType &event ) {
    return joystick != nullptr && event.which == SDL_JoystickInstanceID( joystick );
}

#endif // JOYSTICK_H
