# Phase 2 — Database Foundation

Status: foundation schema v1.

## Tujuan
Database menjadi single source of truth untuk operasi Al Fauzi Tour. Browser/IndexedDB hanya berfungsi sebagai cache, draft, dan outbox sinkronisasi.

## Yang sudah dimodelkan
Organization, branch, RBAC, user, agent, jamaah, package, departure, booking, invoice, payment, document metadata, idempotency registry, transactional outbox, dan audit log.

## Proteksi concurrency & duplicate
- UUID untuk primary key.
- `version` pada entity mutable untuk optimistic concurrency.
- Unique constraint untuk kode bisnis dan nomor dokumen.
- Jamaah hanya dapat memiliki satu booking untuk departure yang sama.
- `idempotency_keys` mencegah retry request menciptakan transaksi ganda.
- `outbox_events` memisahkan commit transaksi dari pekerjaan asynchronous.
- Semua waktu server menggunakan `timestamptz`.

## Multi-tenant boundary
Semua data bisnis utama membawa `organization_id`; data cabang membawa `branch_id` bila relevan. Enforcement authorization/RLS akan difinalisasi bersama Phase 3 Auth + RBAC agar policy mengikuti model identity yang benar.

## File
File besar tidak disimpan sebagai base64/blob di PostgreSQL. Tabel `documents` hanya menyimpan metadata dan `storage_key` menuju object storage.

## Migration rule
Jangan mengedit migration yang sudah pernah dijalankan di production. Perubahan berikutnya harus dibuat sebagai migration baru berurutan.

## Sebelum production
Schema ini harus melewati integration test, migration test, backup/restore test, concurrency test, dan load test. Provider PostgreSQL belum dipilih sehingga belum ada database production yang dibuat pada tahap ini.
