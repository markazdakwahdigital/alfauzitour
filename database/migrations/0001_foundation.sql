-- Al Fauzi Tour Smart System
-- Phase 2: Database Foundation v1
-- PostgreSQL 15+
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(32) NOT NULL UNIQUE,
  name varchar(160) NOT NULL,
  legal_name varchar(200),
  status varchar(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
  version integer NOT NULL DEFAULT 1 CHECK (version > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  code varchar(32) NOT NULL,
  name varchar(160) NOT NULL,
  phone varchar(32),
  email varchar(254),
  address text,
  status varchar(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
  version integer NOT NULL DEFAULT 1 CHECK (version > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, code)
);

CREATE TABLE roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(40) NOT NULL UNIQUE,
  name varchar(100) NOT NULL,
  scope varchar(20) NOT NULL CHECK (scope IN ('organization','branch','agent','jamaah')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(100) NOT NULL UNIQUE,
  description varchar(240),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE role_permissions (
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY(role_id, permission_id)
);

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  branch_id uuid REFERENCES branches(id),
  role_id uuid NOT NULL REFERENCES roles(id),
  full_name varchar(160) NOT NULL,
  email varchar(254),
  whatsapp varchar(32),
  password_hash text,
  status varchar(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','suspended','disabled')),
  email_verified_at timestamptz,
  whatsapp_verified_at timestamptz,
  last_login_at timestamptz,
  version integer NOT NULL DEFAULT 1 CHECK (version > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (email IS NOT NULL OR whatsapp IS NOT NULL)
);
CREATE UNIQUE INDEX users_org_email_uq ON users(organization_id, lower(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX users_org_whatsapp_uq ON users(organization_id, whatsapp) WHERE whatsapp IS NOT NULL;

CREATE TABLE agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  branch_id uuid REFERENCES branches(id),
  user_id uuid UNIQUE REFERENCES users(id),
  agent_code varchar(40) NOT NULL,
  status varchar(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id, agent_code)
);

CREATE TABLE jamaah (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  branch_id uuid REFERENCES branches(id),
  user_id uuid UNIQUE REFERENCES users(id),
  agent_id uuid REFERENCES agents(id),
  jamaah_code varchar(40) NOT NULL,
  full_name varchar(160) NOT NULL,
  nik varchar(32),
  passport_no varchar(40),
  phone varchar(32),
  email varchar(254),
  birth_date date,
  gender varchar(20),
  status varchar(24) NOT NULL DEFAULT 'prospect',
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id, jamaah_code)
);
CREATE INDEX jamaah_org_branch_idx ON jamaah(organization_id, branch_id);
CREATE INDEX jamaah_agent_idx ON jamaah(agent_id);
CREATE INDEX jamaah_phone_idx ON jamaah(phone);

CREATE TABLE packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  package_code varchar(40) NOT NULL,
  name varchar(180) NOT NULL,
  package_type varchar(24) NOT NULL CHECK(package_type IN ('umrah','hajj','other')),
  description text,
  base_price numeric(18,2) NOT NULL CHECK(base_price >= 0),
  currency char(3) NOT NULL DEFAULT 'IDR',
  status varchar(20) NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published','closed','archived')),
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id, package_code)
);

CREATE TABLE departures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  package_id uuid NOT NULL REFERENCES packages(id),
  departure_code varchar(40) NOT NULL,
  departure_date date NOT NULL,
  return_date date,
  quota integer NOT NULL CHECK(quota >= 0),
  status varchar(24) NOT NULL DEFAULT 'scheduled',
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK(return_date IS NULL OR return_date >= departure_date),
  UNIQUE(organization_id, departure_code)
);
CREATE INDEX departures_package_date_idx ON departures(package_id, departure_date);

CREATE TABLE bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  branch_id uuid REFERENCES branches(id),
  booking_no varchar(40) NOT NULL,
  jamaah_id uuid NOT NULL REFERENCES jamaah(id),
  agent_id uuid REFERENCES agents(id),
  departure_id uuid NOT NULL REFERENCES departures(id),
  status varchar(24) NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','confirmed','cancelled','completed')),
  price numeric(18,2) NOT NULL CHECK(price >= 0),
  currency char(3) NOT NULL DEFAULT 'IDR',
  booked_at timestamptz NOT NULL DEFAULT now(),
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id, booking_no),
  UNIQUE(jamaah_id, departure_id)
);
CREATE INDEX bookings_departure_status_idx ON bookings(departure_id,status);
CREATE INDEX bookings_branch_created_idx ON bookings(branch_id,created_at DESC);

CREATE TABLE invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  booking_id uuid NOT NULL REFERENCES bookings(id),
  invoice_no varchar(40) NOT NULL,
  amount numeric(18,2) NOT NULL CHECK(amount >= 0),
  paid_amount numeric(18,2) NOT NULL DEFAULT 0 CHECK(paid_amount >= 0),
  currency char(3) NOT NULL DEFAULT 'IDR',
  due_date date,
  status varchar(20) NOT NULL DEFAULT 'unpaid' CHECK(status IN ('unpaid','partial','paid','void')),
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK(paid_amount <= amount),
  UNIQUE(organization_id, invoice_no)
);

CREATE TABLE payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  invoice_id uuid NOT NULL REFERENCES invoices(id),
  payment_no varchar(40) NOT NULL,
  amount numeric(18,2) NOT NULL CHECK(amount > 0),
  method varchar(32),
  external_reference varchar(120),
  paid_at timestamptz,
  status varchar(20) NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','verified','rejected','refunded')),
  verified_by uuid REFERENCES users(id),
  verified_at timestamptz,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id, payment_no)
);
CREATE INDEX payments_invoice_status_idx ON payments(invoice_id,status);

CREATE TABLE documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  jamaah_id uuid REFERENCES jamaah(id),
  booking_id uuid REFERENCES bookings(id),
  document_type varchar(40) NOT NULL,
  storage_key text NOT NULL,
  original_name text NOT NULL,
  mime_type varchar(120),
  size_bytes bigint CHECK(size_bytes IS NULL OR size_bytes >= 0),
  checksum_sha256 varchar(64),
  status varchar(20) NOT NULL DEFAULT 'uploaded',
  version integer NOT NULL DEFAULT 1,
  created_by uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX documents_jamaah_type_idx ON documents(jamaah_id,document_type);

CREATE TABLE idempotency_keys (
  organization_id uuid NOT NULL REFERENCES organizations(id),
  idempotency_key varchar(160) NOT NULL,
  request_hash varchar(64) NOT NULL,
  response_status integer,
  response_body jsonb,
  resource_type varchar(60),
  resource_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  PRIMARY KEY(organization_id,idempotency_key)
);
CREATE INDEX idempotency_expiry_idx ON idempotency_keys(expires_at);

CREATE TABLE outbox_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  aggregate_type varchar(60) NOT NULL,
  aggregate_id uuid NOT NULL,
  event_type varchar(100) NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status varchar(20) NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','processing','published','failed')),
  attempts integer NOT NULL DEFAULT 0 CHECK(attempts >= 0),
  available_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX outbox_pending_idx ON outbox_events(status,available_at) WHERE status IN ('pending','failed');

CREATE TABLE audit_logs (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  organization_id uuid NOT NULL REFERENCES organizations(id),
  actor_user_id uuid REFERENCES users(id),
  action varchar(100) NOT NULL,
  entity_type varchar(60) NOT NULL,
  entity_id uuid,
  request_id varchar(100),
  before_data jsonb,
  after_data jsonb,
  ip_hash varchar(128),
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_org_created_idx ON audit_logs(organization_id,created_at DESC);
CREATE INDEX audit_entity_idx ON audit_logs(entity_type,entity_id,created_at DESC);

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at=now(); RETURN NEW; END $$;

DO $$ DECLARE t text; BEGIN
FOREACH t IN ARRAY ARRAY['organizations','branches','users','agents','jamaah','packages','departures','bookings','invoices','payments','documents']
LOOP EXECUTE format('CREATE TRIGGER %I_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at()',t,t); END LOOP;
END $$;

INSERT INTO roles(code,name,scope) VALUES
('owner','Owner / Super Admin','organization'),
('staff_pusat','Staff Pusat','organization'),
('manager_cabang','Manager Cabang','branch'),
('staff_cabang','Staff Cabang','branch'),
('agen','Agen','agent'),
('jamaah','Jamaah','jamaah');

COMMIT;
