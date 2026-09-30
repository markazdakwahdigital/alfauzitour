-- Phase 2 foundation smoke tests.
-- Run in a disposable PostgreSQL database after 0001_foundation.sql.

DO $$
DECLARE org uuid; pkg uuid; dep uuid; j uuid; b uuid;
BEGIN
  INSERT INTO organizations(code,name) VALUES('TEST','Test Org') RETURNING id INTO org;
  INSERT INTO packages(organization_id,package_code,name,package_type,base_price)
    VALUES(org,'PKG-1','Umrah Test','umrah',1000000) RETURNING id INTO pkg;
  INSERT INTO departures(organization_id,package_id,departure_code,departure_date,quota)
    VALUES(org,pkg,'DEP-1',current_date+30,10) RETURNING id INTO dep;
  INSERT INTO jamaah(organization_id,jamaah_code,full_name)
    VALUES(org,'JMH-1','Jamaah Test') RETURNING id INTO j;
  INSERT INTO bookings(organization_id,booking_no,jamaah_id,departure_id,price)
    VALUES(org,'BKG-1',j,dep,1000000) RETURNING id INTO b;

  BEGIN
    INSERT INTO bookings(organization_id,booking_no,jamaah_id,departure_id,price)
      VALUES(org,'BKG-2',j,dep,1000000);
    RAISE EXCEPTION 'duplicate jamaah/departure protection failed';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO payments(organization_id,invoice_id,payment_no,amount)
      VALUES(org,gen_random_uuid(),'PAY-BAD',1000);
    RAISE EXCEPTION 'foreign key protection failed';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  RAISE NOTICE 'Foundation smoke tests PASS';
  RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='ROLLBACK_TEST';
EXCEPTION WHEN SQLSTATE 'P0001' THEN
  IF SQLERRM <> 'ROLLBACK_TEST' THEN RAISE; END IF;
END $$;
