# Data Integrity & Transaction Rules

## Booking
Create booking harus berada dalam transaction:
1. validasi organization/branch/jamaah/departure
2. lock/check kapasitas departure
3. insert booking
4. buat invoice bila diperlukan
5. insert outbox event
6. commit
Retry command menggunakan Idempotency-Key yang sama.

## Payment verification
Verifikasi pembayaran harus transaction-safe:
1. lock payment + invoice terkait
2. pastikan payment belum diverifikasi
3. ubah status payment
4. hitung ulang paid_amount dari pembayaran verified
5. ubah invoice status unpaid/partial/paid
6. tulis audit log + outbox event
7. commit

## Optimistic update
Client membaca version N dan mengirim expectedVersion=N.
UPDATE ... SET ..., version=version+1 WHERE id=? AND version=N.
0 row updated berarti conflict dan API mengembalikan HTTP 409.

## Outbox
Worker mengambil event pending dengan locking/skip-locked, memproses secara idempotent, lalu menandai published. Kegagalan memakai bounded retry; dead-letter strategy akan ditetapkan saat queue provider dipilih.

## Data isolation
API tidak boleh menerima organization_id dari client sebagai sumber otoritatif. organization/branch scope diturunkan dari authenticated principal/session.
