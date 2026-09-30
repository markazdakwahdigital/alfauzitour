# API Contract v1

Base path: /api/v1

## Headers
Every request: X-Request-ID
Authenticated request: Authorization: Bearer <token>
Mutation with retry risk: Idempotency-Key
Versioned update: If-Match: <version>

## Standard success
{ "data": {}, "meta": { "requestId": "..." } }

## Standard error
{ "code": "VALIDATION_ERROR", "message": "...", "details": {} }

## Important status
400 invalid request
401 unauthenticated
403 unauthorized
404 not found
409 version/idempotency conflict
422 business rule violation
429 rate limited
500 server error
503 temporary unavailable

## Initial endpoints
POST /auth/login
POST /auth/register
POST /auth/refresh
POST /auth/logout
GET  /me

GET/POST /jamaah
GET/PATCH /jamaah/:id
GET/POST /agents
GET/PATCH /agents/:id
GET/POST /bookings
GET/PATCH /bookings/:id
GET/POST /payments
GET/PATCH /payments/:id
GET /dashboard/summary

Implementation backend belum dipilih pada Phase 1. Kontrak ini sengaja vendor-neutral.
