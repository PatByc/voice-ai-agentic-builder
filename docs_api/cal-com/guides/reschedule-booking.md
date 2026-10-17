<!-- Source: https://cal.com/docs/api-reference/v2/bookings/reschedule-a-booking.md -->
<!-- Retrieved: 2026-11-06T08:40:36Z -->

> ## Documentation Index
> Fetch the complete documentation index at: https://cal.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Reschedule a booking

> Reschedule a booking or seated booking.

    Reschedulable booking statuses:
    - `accepted` — the confirmed booking is moved to the new start time.
    - `pending` — a booking awaiting host confirmation can be rescheduled. The new booking stays `pending` until the host confirms or declines it.

    Non-reschedulable booking statuses (endpoint responds with `400 Bad Request`):
    - `cancelled` — the booking has already been cancelled. If it was cancelled because it was previously rescheduled, the error message includes the UID of the booking it was rescheduled to.
    - `rejected` — the host declined the original confirmation-required request. Create a new booking instead.
    - `awaiting_host` — an instant meeting that is live and waiting for a host to join. Create a new booking instead.

    <Note>Please make sure to pass in the cal-api-version header value as mentioned in the Headers section. Not passing the correct value will default to an older version of this endpoint.</Note>
    



## OpenAPI

````yaml /api-reference/v2/openapi.json post /v2/bookings/{bookingUid}/reschedule
openapi: 3.0.0
info:
  title: Cal.com API v2
  description: ''
  version: 1.0.0
  contact: {}
servers: []
security: []
tags: []
paths:
  /v2/bookings/{bookingUid}/reschedule:
    post:
      tags:
        - Bookings
      summary: Reschedule a booking
      description: |-
        Reschedule a booking or seated booking.

            Reschedulable booking statuses:
            - `accepted` — the confirmed booking is moved to the new start time.
            - `pending` — a booking awaiting host confirmation can be rescheduled. The new booking stays `pending` until the host confirms or declines it.

            Non-reschedulable booking statuses (endpoint responds with `400 Bad Request`):
            - `cancelled` — the booking has already been cancelled. If it was cancelled because it was previously rescheduled, the error message includes the UID of the booking it was rescheduled to.
            - `rejected` — the host declined the original confirmation-required request. Create a new booking instead.
            - `awaiting_host` — an instant meeting that is live and waiting for a host to join. Create a new booking instead.

            <Note>Please make sure to pass in the cal-api-version header value as mentioned in the Headers section. Not passing the correct value will default to an older version of this endpoint.</Note>
            
      operationId: BookingsController_2026_02_25_rescheduleBooking
      parameters:
        - name: cal-api-version
          in: header
          description: Must be set to 2026-02-25.
          required: true
          schema:
            type: string
            example: '2026-02-25'
            default: '2026-02-25'
        - name: bookingUid
          required: true
          in: path
          schema:
            type: string
        - name: Authorization
          in: header
          description: >-
            value must be `Bearer <token>` where `<token>` is api key prefixed
            with cal_, managed user access token, or OAuth access token
          required: false
          schema:
            type: string
        - name: x-cal-secret-key
          in: header
          description: For platform customers - OAuth client secret key
          required: false
          schema:
            type: string
        - name: x-cal-client-id
          in: header
          description: For platform customers - OAuth client ID
          required: false
          schema:
            type: string
      requestBody:
        required: true
        description: >-
          Accepts different types of reschedule booking input: Standard or
          Recurring Booking, or Seated Booking. If you're rescheduling a seated
          booking as org admin of booking host, pass booking input for Standard
          or Recurring Booking along with your access token in the request
          header.

                If you are rescheduling a seated booking for an event type with 'show attendees' disabled, then to retrieve attendees in the response either set 'show attendees' to true on event type level or
                you have to provide an authentication method of event type owner, host, team admin or owner or org admin or owner.
        content:
          application/json:
            schema:
              oneOf:
                - $ref: '#/components/schemas/RescheduleBookingInput_2024_08_13'
                  title: Standard or Recurring Booking
                - $ref: '#/components/schemas/RescheduleSeatedBookingInput_2024_08_13'
                  title: Seated Booking
      responses:
        '201':
          description: ''
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/RescheduleBookingOutput_2024_08_13'
components:
  schemas:
    RescheduleBookingInput_2024_08_13:
      type: object
      properties:
        start:
          type: string
          description: Start time in ISO 8601 format for the new booking
          example: '2024-08-13T10:00:00Z'
          format: date-time
        lengthInMinutes:
          type: number
          minimum: 1
          example: 30
          description: >-
            If the event type has multiple possible lengths, you can pass the
            new booking length here. If not provided then the original booking
            length is kept.
        rescheduledBy:
          type: string
          description: >-
            Email of the person who is rescheduling the booking - only needed
            when rescheduling a booking that requires a confirmation.

            If event type owner email is provided then rescheduled booking will
            be automatically confirmed. If attendee email or no email is passed
            then the event type

            owner will have to confirm the rescheduled booking.
        reschedulingReason:
          type: string
          example: User requested reschedule
          description: Reason for rescheduling the booking
        emailVerificationCode:
          type: string
          description: >-
            Email verification code required when event type has email
            verification enabled.
          example: '123456'
        rescheduleWithSameHost:
          type: boolean
          description: >-
            Only for round robin event types that let the person rescheduling
            choose the host. True keeps the original host, false lets round
            robin pick from the whole team. Ignored for every other event type.
          example: true
        allowConflicts:
          type: boolean
          description: >-
            When true, availability conflict checks are bypassed for an
            authenticated user who has access through the existing event owner,
            host, assigned user, team admin or organization admin checks. Team-
            and organization-scoped keys are restricted to events in their
            stored team or organization. Otherwise this parameter is silently
            ignored. Only supported on the 2026-02-25 and 2026-05-01 API
            versions.
          example: true
        allowBookingOutOfBounds:
          type: boolean
          description: >-
            When true, booking time out-of-bounds checks are bypassed, allowing
            bookings outside the normally permitted scheduling window, for an
            authenticated user who has access through the existing event owner,
            host, assigned user, team admin or organization admin checks. Team-
            and organization-scoped keys are restricted to events in their
            stored team or organization. Otherwise this parameter is silently
            ignored. Only supported on the 2026-02-25 and 2026-05-01 API
            versions.
          example: true
        skipBookingLimits:
          type: boolean
          description: >-
            When true, booking limit checks (event type, team, and per-host
            count and duration limits) are bypassed for an authenticated user
            who has access through the existing event owner, host, assigned
            user, team admin or organization admin checks. Team- and
            organization-scoped keys are restricted to events in their stored
            team or organization. Otherwise this parameter is silently ignored.
            Only supported on the 2026-02-25 and 2026-05-01 API versions.
          example: true
      required:
        - start
    RescheduleSeatedBookingInput_2024_08_13:
      type: object
      properties:
        start:
          type: string
          description: Start time in ISO 8601 format for the new booking
          example: '2024-08-13T10:00:00Z'
          format: date-time
        rescheduledBy:
          type: string
          description: >-
            Email of the person who is rescheduling the booking - only needed
            when rescheduling a booking that requires a confirmation.

            If event type owner email is provided then rescheduled booking will
            be automatically confirmed. If attendee email or no email is passed
            then the event type

            owner will have to confirm the rescheduled booking.
        seatUid:
          type: string
          example: 3be561a9-31f1-4b8e-aefc-9d9a085f0dd1
          description: Uid of the specific seat within booking.
        emailVerificationCode:
          type: string
          description: >-
            Email verification code required when event type has email
            verification enabled.
          example: '123456'
        allowConflicts:
          type: boolean
          description: >-
            When true, availability conflict checks are bypassed for an
            authenticated user who has access through the existing event owner,
            host, assigned user, team admin or organization admin checks. Team-
            and organization-scoped keys are restricted to events in their
            stored team or organization. Otherwise this parameter is silently
            ignored. Only supported on the 2026-02-25 and 2026-05-01 API
            versions.
          example: true
        allowBookingOutOfBounds:
          type: boolean
          description: >-
            When true, booking time out-of-bounds checks are bypassed, allowing
            bookings outside the normally permitted scheduling window, for an
            authenticated user who has access through the existing event owner,
            host, assigned user, team admin or organization admin checks. Team-
            and organization-scoped keys are restricted to events in their
            stored team or organization. Otherwise this parameter is silently
            ignored. Only supported on the 2026-02-25 and 2026-05-01 API
            versions.
          example: true
        skipBookingLimits:
          type: boolean
          description: >-
            When true, booking limit checks (event type, team, and per-host
            count and duration limits) are bypassed for an authenticated user
            who has access through the existing event owner, host, assigned
            user, team admin or organization admin checks. Team- and
            organization-scoped keys are restricted to events in their stored
            team or organization. Otherwise this parameter is silently ignored.
            Only supported on the 2026-02-25 and 2026-05-01 API versions.
          example: true
      required:
        - start
        - seatUid
    RescheduleBookingOutput_2024_08_13:
      type: object
      properties:
        status:
          enum:
            - success
            - error
          type: string
          example: success
        data:
          oneOf:
            - $ref: '#/components/schemas/BookingOutput_2024_08_13'
              title: Booking
            - $ref: '#/components/schemas/RecurringBookingOutput_2024_08_13'
              title: Recurring Booking
            - $ref: '#/components/schemas/CreateSeatedBookingOutput_2024_08_13'
              title: Seated Booking
            - $ref: >-
                #/components/schemas/CreateRecurringSeatedBookingOutput_2024_08_13
              title: Recurring Seated Booking
          description: >-
            Booking data, which can be either a BookingOutput object or a
            RecurringBookingOutput object
      required:
        - status
        - data
    BookingOutput_2024_08_13:
      type: object
      properties:
        id:
          type: number
          example: 123
        uid:
          type: string
          example: booking_uid_123
        title:
          type: string
          example: Consultation
        description:
          type: string
          example: Learn how to integrate scheduling into marketplace.
        hosts:
          type: array
          items:
            $ref: '#/components/schemas/BookingHost'
        status:
          enum:
            - cancelled
            - accepted
            - rejected
            - pending
            - awaiting_host
          type: string
          example: accepted
          description: >-
            `awaiting_host` is an instant meeting that is live and waiting for a
            host to join.
        cancellationReason:
          type: string
          example: User requested cancellation
        cancelledByEmail:
          type: string
          format: email
          example: canceller@example.com
        reschedulingReason:
          type: string
          example: User rescheduled the event
        rescheduledByEmail:
          type: string
          format: email
          example: rescheduler@example.com
        rescheduledFromUid:
          type: string
          example: previous_uid_123
          description: UID of the previous booking from which this booking was rescheduled.
        rescheduledToUid:
          type: string
          example: new_uid_456
          description: UID of the new booking to which this booking was rescheduled.
        start:
          type: string
          example: '2024-08-13T15:30:00Z'
          format: date-time
        end:
          type: string
          example: '2024-08-13T16:30:00Z'
          format: date-time
        duration:
          type: number
          example: 60
        eventTypeId:
          type: number
          example: 50
          deprecated: true
          description: Deprecated - rely on 'eventType' object containing the id instead.
        eventType:
          $ref: '#/components/schemas/EventType'
        eventUuid:
          type: string
          nullable: true
          example: 0199b5d2-7c1e-7f3a-9b4d-2e6f8a1c3d5e
          description: >-
            UUID of the Event this booking belongs to. Pass it to `GET
            /v2/events/{uuid}` to fetch the Event. `null` when the booking is
            not for an Event.
        meetingUrl:
          type: string
          format: uri
          description: Deprecated - rely on 'location' field instead.
          example: https://example.com/recurring-meeting
          deprecated: true
        location:
          type: string
          example: https://example.com/meeting
        absentHost:
          type: boolean
          example: true
        createdAt:
          type: string
          example: '2024-08-13T15:30:00Z'
          format: date-time
        updatedAt:
          type: string
          nullable: true
          example: '2024-08-13T15:30:00Z'
          format: date-time
        metadata:
          type: object
          additionalProperties:
            type: string
          example:
            key: value
        rating:
          type: number
          example: 4
        icsUid:
          type: string
          example: ics_uid_123
          description: UID of ICS event.
        attendees:
          type: array
          items:
            $ref: '#/components/schemas/BookingAttendee'
        guests:
          example:
            - guest1@example.com
            - guest2@example.com
          type: array
          items:
            type: string
        bookingFieldsResponses:
          type: object
          additionalProperties: true
          description: >-
            Booking field responses consisting of an object with booking field
            slug as keys and user response as values.
          example:
            customField: customValue
      required:
        - id
        - uid
        - title
        - description
        - hosts
        - status
        - start
        - end
        - duration
        - eventTypeId
        - eventType
        - location
        - absentHost
        - createdAt
        - updatedAt
        - attendees
        - bookingFieldsResponses
    RecurringBookingOutput_2024_08_13:
      type: object
      properties:
        id:
          type: number
          example: 123
        uid:
          type: string
          example: booking_uid_123
        title:
          type: string
          example: Consultation
        description:
          type: string
          example: Learn how to integrate scheduling into marketplace.
        hosts:
          type: array
          items:
            $ref: '#/components/schemas/BookingHost'
        status:
          enum:
            - cancelled
            - accepted
            - rejected
            - pending
            - awaiting_host
          type: string
          example: accepted
          description: >-
            `awaiting_host` is an instant meeting that is live and waiting for a
            host to join.
        cancellationReason:
          type: string
          example: User requested cancellation
        cancelledByEmail:
          type: string
          format: email
          example: canceller@example.com
        reschedulingReason:
          type: string
          example: User rescheduled the event
        rescheduledByEmail:
          type: string
          format: email
          example: rescheduler@example.com
        rescheduledFromUid:
          type: string
          example: previous_uid_123
          description: UID of the previous booking from which this booking was rescheduled.
        rescheduledToUid:
          type: string
          example: new_uid_456
          description: UID of the new booking to which this booking was rescheduled.
        start:
          type: string
          example: '2024-08-13T15:30:00Z'
          format: date-time
        end:
          type: string
          example: '2024-08-13T16:30:00Z'
          format: date-time
        duration:
          type: number
          example: 60
        eventTypeId:
          type: number
          example: 50
          deprecated: true
          description: Deprecated - rely on 'eventType' object containing the id instead.
        eventType:
          $ref: '#/components/schemas/EventType'
        eventUuid:
          type: string
          nullable: true
          example: 0199b5d2-7c1e-7f3a-9b4d-2e6f8a1c3d5e
          description: >-
            UUID of the Event this booking belongs to. Pass it to `GET
            /v2/events/{uuid}` to fetch the Event. `null` when the booking is
            not for an Event.
        meetingUrl:
          type: string
          format: uri
          description: Deprecated - rely on 'location' field instead.
          example: https://example.com/recurring-meeting
          deprecated: true
        location:
          type: string
          example: https://example.com/meeting
        absentHost:
          type: boolean
          example: true
        createdAt:
          type: string
          example: '2024-08-13T15:30:00Z'
          format: date-time
        updatedAt:
          type: string
          nullable: true
          example: '2024-08-13T15:30:00Z'
          format: date-time
        metadata:
          type: object
          additionalProperties:
            type: string
          example:
            key: value
        rating:
          type: number
          example: 4
        icsUid:
          type: string
          example: ics_uid_123
          description: UID of ICS event.
        attendees:
          type: array
          items:
            $ref: '#/components/schemas/BookingAttendee'
        guests:
          example:
            - guest1@example.com
            - guest2@example.com
          type: array
          items:
            type: string
        bookingFieldsResponses:
          type: object
          additionalProperties: true
          description: >-
            Booking field responses consisting of an object with booking field
            slug as keys and user response as values.
          example:
            customField: customValue
        recurringBookingUid:
          type: string
          example: recurring_uid_987
      required:
        - id
        - uid
        - title
        - description
        - hosts
        - status
        - start
        - end
        - duration
        - eventTypeId
        - eventType
        - location
        - absentHost
        - createdAt
        - updatedAt
        - attendees
        - bookingFieldsResponses
        - recurringBookingUid
    CreateSeatedBookingOutput_2024_08_13:
      type: object
      properties:
        id:
          type: number
          example: 123
        uid:
          type: string
          example: booking_uid_123
        title:
          type: string
          example: Consultation
        description:
          type: string
          example: Learn how to integrate scheduling into marketplace.
        hosts:
          type: array
          items:
            $ref: '#/components/schemas/BookingHost'
        status:
          enum:
            - cancelled
            - accepted
            - rejected
            - pending
            - awaiting_host
          type: string
          example: accepted
          description: >-
            `awaiting_host` is an instant meeting that is live and waiting for a
            host to join.
        cancellationReason:
          type: string
          example: User requested cancellation
        cancelledByEmail:
          type: string
          format: email
          example: canceller@example.com
        reschedulingReason:
          type: string
          example: User rescheduled the event
        rescheduledByEmail:
          type: string
          format: email
          example: rescheduler@example.com
        rescheduledFromUid:
          type: string
          example: previous_uid_123
          description: UID of the previous booking from which this booking was rescheduled.
        rescheduledToUid:
          type: string
          example: new_uid_456
          description: UID of the new booking to which this booking was rescheduled.
        start:
          type: string
          example: '2024-08-13T15:30:00Z'
          format: date-time
        end:
          type: string
          example: '2024-08-13T16:30:00Z'
          format: date-time
        duration:
          type: number
          example: 60
        eventTypeId:
          type: number
          example: 50
          deprecated: true
          description: Deprecated - rely on 'eventType' object containing the id instead.
        eventType:
          $ref: '#/components/schemas/EventType'
        eventUuid:
          type: string
          nullable: true
          example: 0199b5d2-7c1e-7f3a-9b4d-2e6f8a1c3d5e
          description: >-
            UUID of the Event this booking belongs to. Pass it to `GET
            /v2/events/{uuid}` to fetch the Event. `null` when the booking is
            not for an Event.
        meetingUrl:
          type: string
          format: uri
          description: Deprecated - rely on 'location' field instead.
          example: https://example.com/recurring-meeting
          deprecated: true
        location:
          type: string
          example: https://example.com/meeting
        absentHost:
          type: boolean
          example: true
        createdAt:
          type: string
          example: '2024-08-13T15:30:00Z'
          format: date-time
        updatedAt:
          type: string
          nullable: true
          example: '2024-08-13T15:30:00Z'
          format: date-time
        metadata:
          type: object
          additionalProperties:
            type: string
          example:
            key: value
        rating:
          type: number
          example: 4
        icsUid:
          type: string
          example: ics_uid_123
          description: UID of ICS event.
        seatUid:
          type: string
          example: 3be561a9-31f1-4b8e-aefc-9d9a085f0dd1
        attendees:
          type: array
          items:
            $ref: '#/components/schemas/SeatedAttendee'
      required:
        - id
        - uid
        - title
        - description
        - hosts
        - status
        - start
        - end
        - duration
        - eventTypeId
        - eventType
        - location
        - absentHost
        - createdAt
        - updatedAt
        - seatUid
        - attendees
    CreateRecurringSeatedBookingOutput_2024_08_13:
      type: object
      properties:
        id:
          type: number
          example: 123
        uid:
          type: string
          example: booking_uid_123
        title:
          type: string
          example: Consultation
        description:
          type: string
          example: Learn how to integrate scheduling into marketplace.
        hosts:
          type: array
          items:
            $ref: '#/components/schemas/BookingHost'
        status:
          enum:
            - cancelled
            - accepted
            - rejected
            - pending
            - awaiting_host
          type: string
          example: accepted
          description: >-
            `awaiting_host` is an instant meeting that is live and waiting for a
            host to join.
        cancellationReason:
          type: string
          example: User requested cancellation
        cancelledByEmail:
          type: string
          format: email
          example: canceller@example.com
        reschedulingReason:
          type: string
          example: User rescheduled the event
        rescheduledByEmail:
          type: string
          format: email
          example: rescheduler@example.com
        rescheduledFromUid:
          type: string
          example: previous_uid_123
          description: UID of the previous booking from which this booking was rescheduled.
        rescheduledToUid:
          type: string
          example: new_uid_456
          description: UID of the new booking to which this booking was rescheduled.
        start:
          type: string
          example: '2024-08-13T15:30:00Z'
          format: date-time
        end:
          type: string
          example: '2024-08-13T16:30:00Z'
          format: date-time
        duration:
          type: number
          example: 60
        eventTypeId:
          type: number
          example: 50
          deprecated: true
          description: Deprecated - rely on 'eventType' object containing the id instead.
        eventType:
          $ref: '#/components/schemas/EventType'
        eventUuid:
          type: string
          nullable: true
          example: 0199b5d2-7c1e-7f3a-9b4d-2e6f8a1c3d5e
          description: >-
            UUID of the Event this booking belongs to. Pass it to `GET
            /v2/events/{uuid}` to fetch the Event. `null` when the booking is
            not for an Event.
        meetingUrl:
          type: string
          format: uri
          description: Deprecated - rely on 'location' field instead.
          example: https://example.com/recurring-meeting
          deprecated: true
        location:
          type: string
          example: https://example.com/meeting
        absentHost:
          type: boolean
          example: true
        createdAt:
          type: string
          example: '2024-08-13T15:30:00Z'
          format: date-time
        updatedAt:
          type: string
          nullable: true
          example: '2024-08-13T15:30:00Z'
          format: date-time
        metadata:
          type: object
          additionalProperties:
            type: string
          example:
            key: value
        rating:
          type: number
          example: 4
        icsUid:
          type: string
          example: ics_uid_123
          description: UID of ICS event.
        seatUid:
          type: string
          example: 3be561a9-31f1-4b8e-aefc-9d9a085f0dd1
        attendees:
          type: array
          items:
            $ref: '#/components/schemas/SeatedAttendee'
        recurringBookingUid:
          type: string
          example: recurring_uid_987
      required:
        - id
        - uid
        - title
        - description
        - hosts
        - status
        - start
        - end
        - duration
        - eventTypeId
        - eventType
        - location
        - absentHost
        - createdAt
        - updatedAt
        - seatUid
        - attendees
        - recurringBookingUid
    BookingHost:
      type: object
      properties:
        id:
          type: number
          example: 1
        uuid:
          type: string
          format: uuid
          example: 3f2504e0-4f89-41d3-9a0c-0305e82c3301
        name:
          type: string
          example: Jane Doe
        email:
          type: string
          example: jane100@example.com
        displayEmail:
          type: string
          example: jane100@example.com
          description: Clean email for display purposes
        username:
          type: string
          example: jane100
        timeZone:
          type: string
          example: America/Los_Angeles
      required:
        - id
        - uuid
        - name
        - email
        - displayEmail
        - username
        - timeZone
    EventType:
      type: object
      properties:
        id:
          type: number
          example: 1
        slug:
          type: string
          example: some-event
      required:
        - id
        - slug
    BookingAttendee:
      type: object
      properties:
        name:
          type: string
          example: John Doe
        email:
          type: string
          example: john@example.com
        displayEmail:
          type: string
          example: john@example.com
          description: Clean email for display purposes
        timeZone:
          type: string
          example: America/New_York
        language:
          enum:
            - ar
            - ca
            - de
            - es
            - eu
            - he
            - id
            - ja
            - lv
            - pl
            - ro
            - sr
            - th
            - vi
            - az
            - cs
            - el
            - es-419
            - fi
            - hr
            - it
            - km
            - nl
            - pt
            - ru
            - sv
            - tr
            - zh-CN
            - bg
            - da
            - en
            - et
            - fr
            - hu
            - iw
            - ko
            - 'no'
            - pt-BR
            - sk
            - sl
            - ta
            - uk
            - zh-TW
            - bn
          type: string
          example: en
        absent:
          type: boolean
          example: false
        phoneNumber:
          type: string
          example: '+1234567890'
      required:
        - name
        - email
        - displayEmail
        - timeZone
        - absent
    SeatedAttendee:
      type: object
      properties:
        name:
          type: string
          example: John Doe
        email:
          type: string
          example: john@example.com
        displayEmail:
          type: string
          example: john@example.com
          description: Clean email for display purposes
        timeZone:
          type: string
          example: America/New_York
        language:
          enum:
            - ar
            - ca
            - de
            - es
            - eu
            - he
            - id
            - ja
            - lv
            - pl
            - ro
            - sr
            - th
            - vi
            - az
            - cs
            - el
            - es-419
            - fi
            - hr
            - it
            - km
            - nl
            - pt
            - ru
            - sv
            - tr
            - zh-CN
            - bg
            - da
            - en
            - et
            - fr
            - hu
            - iw
            - ko
            - 'no'
            - pt-BR
            - sk
            - sl
            - ta
            - uk
            - zh-TW
            - bn
          type: string
          example: en
        absent:
          type: boolean
          example: false
        phoneNumber:
          type: string
          example: '+1234567890'
        seatUid:
          type: string
          example: 3be561a9-31f1-4b8e-aefc-9d9a085f0dd1
        createdAt:
          type: string
          example: '2024-08-13T15:30:00Z'
          description: The date and time when the attendee joined the seated booking.
        bookingFieldsResponses:
          type: object
          additionalProperties: true
          description: >-
            Booking field responses consisting of an object with booking field
            slug as keys and user response as values.
          example:
            customField: customValue
        metadata:
          type: object
          additionalProperties:
            type: string
          example:
            key: value
        status:
          type: string
          enum:
            - cancelled
          example: cancelled
          description: >-
            Present on API version 2026-02-25 and later when this attendee was
            loaded from a cancelled seat. Omitted for occupied seats.
        confirmationStatus:
          enum:
            - pending
            - accepted
            - rejected
          type: string
          example: accepted
          description: >-
            Confirmation verdict of this live seat. Omitted when the attendee
            has no live seat. An attendee loaded from a cancelled seat has
            status cancelled and does not include confirmationStatus.
      required:
        - name
        - email
        - displayEmail
        - timeZone
        - absent
        - seatUid
        - bookingFieldsResponses

````

This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.