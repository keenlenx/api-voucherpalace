-- ============================================================================
-- Romeo Fox Alpha Voucher Management Platform - Database Schema Only
-- PostgreSQL 15+ Compatible
-- ============================================================================

-- Connect to the database (created by POSTGRES_DB env var)
\connect voucherpalace

-- ============================================================================
-- Create ENUM types (IF NOT EXISTS)
-- ============================================================================
DO $$ BEGIN
    CREATE TYPE invoice_status_enum AS ENUM ('draft', 'issued', 'paid', 'overdue', 'void');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE settlement_status_enum AS ENUM ('pending', 'processing', 'paid', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE tenant_type_enum AS ENUM ('corporate', 'merchant', 'rfa_internal');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_type_enum AS ENUM ('voucher_creation', 'redemption', 'wallet_funding', 'fee_deduction', 'settlement', 'refund');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE usage_limit_type_enum AS ENUM ('single', 'multi', 'unlimited');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM ('super_admin', 'client_admin', 'client_user', 'merchant_admin', 'merchant_staff', 'consumer');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE voucher_status_enum AS ENUM ('active', 'redeemed', 'expired', 'refunded', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE voucher_type_enum AS ENUM ('fixed_amount', 'percentage', 'open_cash');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- Create Functions
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION generate_voucher_code()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    prefix VARCHAR(10) := 'RFA-';
    random_part VARCHAR(20);
    counter INTEGER := 0;
    code_exists BOOLEAN;
BEGIN
    LOOP
        random_part := encode(gen_random_bytes(8), 'hex');
        NEW.code := prefix || to_char(NOW(), 'YYYYMMDD') || '-' || upper(random_part);
        SELECT EXISTS(SELECT 1 FROM vouchers WHERE code = NEW.code) INTO code_exists;
        EXIT WHEN NOT code_exists OR counter >= 10;
        counter := counter + 1;
    END LOOP;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION update_voucher_on_redemption()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE vouchers
    SET 
        remaining_value = NEW.new_balance,
        times_redeemed = times_redeemed + 1,
        status = CASE WHEN NEW.new_balance <= 0 THEN 'redeemed'::voucher_status_enum ELSE status END,
        updated_at = NOW()
    WHERE id = NEW.voucher_id;
    RETURN NEW;
END;
$$;

-- ============================================================================
-- Create Tables in Order of Dependencies
-- ============================================================================

-- 1. Tenants (no dependencies)
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_name VARCHAR(255) NOT NULL,
    tenant_type tenant_type_enum NOT NULL,
    registration_number VARCHAR(100),
    tax_id VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    address TEXT,
    website VARCHAR(255),
    logo_url TEXT,
    status VARCHAR(50) DEFAULT 'active',
    subscription_plan_id UUID,
    wallet_balance NUMERIC(15,2) DEFAULT 0,
    credit_limit NUMERIC(15,2) DEFAULT 0,
    billing_cycle VARCHAR(50) DEFAULT 'monthly',
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    CONSTRAINT valid_status CHECK (status IN ('active', 'suspended', 'pending')),
    CONSTRAINT valid_billing_cycle CHECK (billing_cycle IN ('monthly', 'quarterly', 'annual'))
);

-- 2. Billing Plans (no dependencies)
CREATE TABLE IF NOT EXISTS billing_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_name VARCHAR(255) NOT NULL,
    plan_code VARCHAR(50) NOT NULL UNIQUE,
    plan_type VARCHAR(50) NOT NULL,
    description TEXT,
    monthly_fixed_fee NUMERIC(15,2) DEFAULT 0,
    per_voucher_fee NUMERIC(15,2) DEFAULT 0,
    transaction_percentage NUMERIC(5,2) DEFAULT 0,
    features JSONB DEFAULT '{}',
    is_public BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID,
    updated_by UUID
);

-- 3. Users (depends on tenants)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(50),
    role user_role_enum NOT NULL,
    is_email_verified BOOLEAN DEFAULT false,
    is_phone_verified BOOLEAN DEFAULT false,
    last_login_at TIMESTAMPTZ,
    preferences JSONB DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'active',
    mfa_enabled BOOLEAN DEFAULT false,
    refresh_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT valid_user_status CHECK (status IN ('active', 'suspended', 'locked'))
);

-- 4. Merchants (depends on tenants)
CREATE TABLE IF NOT EXISTS merchants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    merchant_name VARCHAR(255) NOT NULL,
    merchant_code VARCHAR(50) UNIQUE,
    merchant_category VARCHAR(100),
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    latitude NUMERIC(10,8),
    longitude NUMERIC(11,8),
    operating_hours JSONB,
    settlement_period VARCHAR(50) DEFAULT 'weekly',
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- 5. Voucher Templates (depends on tenants)
CREATE TABLE IF NOT EXISTS voucher_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    template_name VARCHAR(255) NOT NULL,
    description TEXT,
    voucher_type voucher_type_enum NOT NULL,
    value_amount NUMERIC(15,2),
    percentage_value NUMERIC(5,2),
    valid_from DATE,
    valid_to DATE,
    usage_limit_type usage_limit_type_enum DEFAULT 'single',
    usage_limit_count INTEGER,
    min_purchase_amount NUMERIC(15,2) DEFAULT 0,
    is_public_visible BOOLEAN DEFAULT false,
    public_price NUMERIC(15,2),
    terms_and_conditions TEXT,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT valid_dates CHECK (valid_to >= valid_from),
    CONSTRAINT valid_percentage CHECK (percentage_value BETWEEN 0 AND 100)
);

-- 6. Voucher Batches (depends on tenants and voucher_templates)
CREATE TABLE IF NOT EXISTS voucher_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    batch_reference VARCHAR(100) NOT NULL UNIQUE,
    voucher_template_id UUID NOT NULL REFERENCES voucher_templates(id),
    total_count INTEGER NOT NULL,
    successful_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0,
    source_file_url TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    error_log TEXT,
    processing_started_at TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- 7. Vouchers (depends on tenants, voucher_templates, users, voucher_batches)
CREATE TABLE IF NOT EXISTS vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voucher_template_id UUID NOT NULL REFERENCES voucher_templates(id),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(100) NOT NULL UNIQUE,
    original_value NUMERIC(15,2) NOT NULL,
    remaining_value NUMERIC(15,2) NOT NULL,
    status voucher_status_enum DEFAULT 'active',
    beneficiary_name VARCHAR(255),
    beneficiary_email VARCHAR(255),
    beneficiary_phone VARCHAR(50),
    beneficiary_user_id UUID REFERENCES users(id),
    batch_id UUID REFERENCES voucher_batches(id),
    expires_at DATE NOT NULL,
    times_redeemed INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT valid_remaining CHECK (remaining_value <= original_value AND remaining_value >= 0)
);

-- 8. Purchase Orders (depends on users, voucher_templates)
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(100) NOT NULL UNIQUE,
    consumer_id UUID REFERENCES users(id),
    consumer_email VARCHAR(255) NOT NULL,
    consumer_phone VARCHAR(50),
    voucher_template_id UUID NOT NULL REFERENCES voucher_templates(id),
    quantity INTEGER DEFAULT 1,
    unit_price NUMERIC(15,2) NOT NULL,
    total_amount NUMERIC(15,2) NOT NULL,
    payment_status payment_status_enum DEFAULT 'pending',
    payment_method VARCHAR(50),
    order_type VARCHAR(50) NOT NULL,
    gift_recipient_email VARCHAR(255),
    gift_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    CONSTRAINT valid_quantity CHECK (quantity > 0),
    CONSTRAINT valid_order_type CHECK (order_type IN ('self', 'gift'))
);

-- 9. Redemptions (depends on vouchers, merchants, users)
CREATE TABLE IF NOT EXISTS redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voucher_id UUID NOT NULL REFERENCES vouchers(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    redeemed_by UUID REFERENCES users(id),
    amount_redeemed NUMERIC(15,2) NOT NULL,
    previous_balance NUMERIC(15,2) NOT NULL,
    new_balance NUMERIC(15,2) NOT NULL,
    receipt_number VARCHAR(100),
    status VARCHAR(50) DEFAULT 'completed',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    CONSTRAINT positive_amount CHECK (amount_redeemed > 0)
);

-- 10. Gift Deliveries (depends on purchase_orders, vouchers)
CREATE TABLE IF NOT EXISTS gift_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    voucher_id UUID NOT NULL REFERENCES vouchers(id) ON DELETE CASCADE,
    delivery_method VARCHAR(50) NOT NULL,
    recipient_address VARCHAR(255) NOT NULL,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    delivery_status VARCHAR(50) DEFAULT 'pending',
    retry_count INTEGER DEFAULT 0,
    error_message TEXT,
    tracking_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Client Subscriptions (depends on tenants, billing_plans)
CREATE TABLE IF NOT EXISTS client_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    billing_plan_id UUID NOT NULL REFERENCES billing_plans(id),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,
    custom_rates JSONB,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- 12. Invoices (depends on tenants)
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number VARCHAR(100) NOT NULL UNIQUE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    items JSONB NOT NULL,
    subtotal NUMERIC(15,2) NOT NULL,
    tax_amount NUMERIC(15,2) DEFAULT 0,
    total_amount NUMERIC(15,2) NOT NULL,
    amount_paid NUMERIC(15,2) DEFAULT 0,
    status invoice_status_enum DEFAULT 'draft',
    payment_reference VARCHAR(255),
    paid_at TIMESTAMPTZ,
    notes TEXT,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- 13. Settlements (depends on merchants)
CREATE TABLE IF NOT EXISTS settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    settlement_number VARCHAR(100) NOT NULL UNIQUE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_redemptions INTEGER DEFAULT 0 NOT NULL,
    total_amount NUMERIC(15,2) NOT NULL,
    rfa_fees NUMERIC(15,2) NOT NULL,
    net_payable NUMERIC(15,2) NOT NULL,
    status settlement_status_enum DEFAULT 'pending',
    payment_reference VARCHAR(255),
    paid_at TIMESTAMPTZ,
    settlement_report_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- 14. Transaction Log (depends on tenants)
CREATE TABLE IF NOT EXISTS transaction_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_type transaction_type_enum NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    source_id UUID NOT NULL,
    from_tenant_id UUID REFERENCES tenants(id),
    to_tenant_id UUID REFERENCES tenants(id),
    amount NUMERIC(15,2) NOT NULL,
    fee_amount NUMERIC(15,2) DEFAULT 0,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- 15. Audit Logs (depends on tenants, users)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. Voucher Merchant Restrictions (depends on voucher_templates, merchants)
CREATE TABLE IF NOT EXISTS voucher_merchant_restrictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voucher_template_id UUID NOT NULL REFERENCES voucher_templates(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE(voucher_template_id, merchant_id)
);

-- ============================================================================
-- Create Indexes (after all tables are created)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_tenant_role ON users(tenant_id, role);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone) WHERE phone IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_merchants_tenant ON merchants(tenant_id);
CREATE INDEX IF NOT EXISTS idx_merchants_code ON merchants(merchant_code);
CREATE INDEX IF NOT EXISTS idx_merchants_category ON merchants(merchant_category);
CREATE INDEX IF NOT EXISTS idx_merchants_location ON merchants(latitude, longitude) WHERE latitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_vouchers_code ON vouchers(code);
CREATE INDEX IF NOT EXISTS idx_vouchers_tenant_status ON vouchers(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_vouchers_expiry ON vouchers(expires_at) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_vouchers_beneficiary_email ON vouchers(beneficiary_email) WHERE beneficiary_email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_vouchers_beneficiary_phone ON vouchers(beneficiary_phone) WHERE beneficiary_phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_vouchers_tenant ON vouchers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_vouchers_batch_id ON vouchers(batch_id);

CREATE INDEX IF NOT EXISTS idx_redemptions_voucher ON redemptions(voucher_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_merchant_date ON redemptions(merchant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_redemptions_created ON redemptions(created_at);
CREATE INDEX IF NOT EXISTS idx_redemptions_voucher_created ON redemptions(voucher_id, created_at);

CREATE INDEX IF NOT EXISTS idx_voucher_templates_tenant ON voucher_templates(tenant_id);
CREATE INDEX IF NOT EXISTS idx_voucher_templates_public ON voucher_templates(is_public_visible) WHERE is_public_visible = true;
CREATE INDEX IF NOT EXISTS idx_voucher_templates_dates ON voucher_templates(valid_from, valid_to);

CREATE INDEX IF NOT EXISTS idx_voucher_batches_tenant ON voucher_batches(tenant_id);
CREATE INDEX IF NOT EXISTS idx_voucher_batches_status ON voucher_batches(status);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_consumer_email ON purchase_orders(consumer_email);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_payment_status ON purchase_orders(payment_status);

CREATE INDEX IF NOT EXISTS idx_invoices_tenant_status ON invoices(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date) WHERE status IN ('issued', 'overdue');
CREATE INDEX IF NOT EXISTS idx_invoices_created_at ON invoices(created_at);

CREATE INDEX IF NOT EXISTS idx_settlements_merchant ON settlements(merchant_id);
CREATE INDEX IF NOT EXISTS idx_settlements_status ON settlements(status);
CREATE INDEX IF NOT EXISTS idx_settlements_period ON settlements(period_start, period_end);

CREATE INDEX IF NOT EXISTS idx_transaction_log_created ON transaction_log(created_at);
CREATE INDEX IF NOT EXISTS idx_transaction_log_source ON transaction_log(source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_transaction_log_tenants ON transaction_log(from_tenant_id, to_tenant_id);
CREATE INDEX IF NOT EXISTS idx_transaction_log_type ON transaction_log(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transaction_log_created_source ON transaction_log(created_at, source_type);

CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_time ON audit_logs(tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_time ON audit_logs(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_lookup ON audit_logs(entity_type, entity_id, created_at);

CREATE INDEX IF NOT EXISTS idx_voucher_merchant_restrictions_template ON voucher_merchant_restrictions(voucher_template_id);

-- ============================================================================
-- Create Triggers
-- ============================================================================
DROP TRIGGER IF EXISTS update_vouchers_updated_at ON vouchers;
CREATE TRIGGER update_vouchers_updated_at BEFORE UPDATE ON vouchers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_merchants_updated_at ON merchants;
CREATE TRIGGER update_merchants_updated_at BEFORE UPDATE ON merchants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tenants_updated_at ON tenants;
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_voucher_templates_updated_at ON voucher_templates;
CREATE TRIGGER update_voucher_templates_updated_at BEFORE UPDATE ON voucher_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_purchase_orders_updated_at ON purchase_orders;
CREATE TRIGGER update_purchase_orders_updated_at BEFORE UPDATE ON purchase_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_settlements_updated_at ON settlements;
CREATE TRIGGER update_settlements_updated_at BEFORE UPDATE ON settlements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS generate_voucher_code_before_insert ON vouchers;
CREATE TRIGGER generate_voucher_code_before_insert BEFORE INSERT ON vouchers FOR EACH ROW WHEN (NEW.code IS NULL) EXECUTE FUNCTION generate_voucher_code();

DROP TRIGGER IF EXISTS update_voucher_after_redemption ON redemptions;
CREATE TRIGGER update_voucher_after_redemption AFTER INSERT ON redemptions FOR EACH ROW EXECUTE FUNCTION update_voucher_on_redemption();

-- ============================================================================
-- Add Comments (Optional but helpful)
-- ============================================================================
COMMENT ON TABLE tenants IS 'Client companies and merchants using the platform';
COMMENT ON TABLE users IS 'All system users including internal staff, client users, and consumers';
COMMENT ON TABLE merchants IS 'Physical merchant locations where vouchers can be redeemed';
COMMENT ON TABLE vouchers IS 'Individual issued vouchers with unique codes';
COMMENT ON COLUMN vouchers.code IS 'Unique voucher code for redemption';
COMMENT ON COLUMN vouchers.remaining_value IS 'For partial redemptions, tracks remaining balance';
COMMENT ON TABLE redemptions IS 'Record of each voucher redemption transaction';
COMMENT ON TABLE transaction_log IS 'Complete audit trail for all financial transactions';
COMMENT ON TABLE audit_logs IS 'System-wide audit trail for compliance and debugging';