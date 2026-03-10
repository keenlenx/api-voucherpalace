-- ============================================================================
-- Romeo Fox Alpha Voucher Management Platform - Complete Schema
-- PostgreSQL 15+ Compatible
-- Safe to run multiple times (uses IF NOT EXISTS)
-- ============================================================================

-- Connect to the database
\connect voucherpalace

-- ============================================================================
-- Enable required extensions
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- Create ENUM types (with IF NOT EXISTS handling)
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
    max_attempts INTEGER := 10;
    code_exists BOOLEAN;
BEGIN
    LOOP
        random_part := encode(gen_random_bytes(8), 'hex');
        NEW.code := prefix || to_char(NOW(), 'YYYYMMDD') || '-' || upper(random_part);
        SELECT EXISTS(SELECT 1 FROM vouchers WHERE code = NEW.code) INTO code_exists;
        EXIT WHEN NOT code_exists OR counter >= max_attempts;
        counter := counter + 1;
    END LOOP;
    
    IF code_exists THEN
        RAISE EXCEPTION 'Could not generate unique voucher code after % attempts', max_attempts;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION update_voucher_on_redemption()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- Update the voucher
    UPDATE vouchers
    SET 
        remaining_value = NEW.new_balance,
        times_redeemed = times_redeemed + 1,
        status = CASE 
            WHEN NEW.new_balance <= 0 THEN 'redeemed'::voucher_status_enum
            ELSE status
        END,
        updated_at = NOW()
    WHERE id = NEW.voucher_id;
    
    -- Log transaction
    INSERT INTO transaction_log (
        transaction_type,
        source_type,
        source_id,
        from_tenant_id,
        to_tenant_id,
        amount,
        description,
        created_by
    ) VALUES (
        'redemption',
        'redemption',
        NEW.id,
        (SELECT tenant_id FROM vouchers WHERE id = NEW.voucher_id),
        (SELECT tenant_id FROM merchants WHERE id = NEW.merchant_id),
        NEW.amount_redeemed,
        'Voucher redemption at merchant',
        NEW.created_by
    );
    
    RETURN NEW;
END;
$$;

-- ============================================================================
-- Create Tables (all with IF NOT EXISTS)
-- ============================================================================

-- 1. Tenants (core table)
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
    wallet_balance NUMERIC(15,2) DEFAULT 0.00,
    credit_limit NUMERIC(15,2) DEFAULT 0.00,
    billing_cycle VARCHAR(50) DEFAULT 'monthly',
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_by UUID,
    CONSTRAINT tenants_status_check CHECK (status IN ('active', 'suspended', 'pending')),
    CONSTRAINT tenants_billing_cycle_check CHECK (billing_cycle IN ('monthly', 'quarterly', 'annual')),
    CONSTRAINT tenants_credit_limit_check CHECK (credit_limit >= 0),
    CONSTRAINT tenants_wallet_balance_check CHECK (wallet_balance >= 0)
);

-- 2. Billing Plans
CREATE TABLE IF NOT EXISTS billing_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_name VARCHAR(255) NOT NULL,
    plan_code VARCHAR(50) NOT NULL UNIQUE,
    plan_type VARCHAR(50) NOT NULL,
    description TEXT,
    monthly_fixed_fee NUMERIC(15,2) DEFAULT 0.00,
    per_voucher_fee NUMERIC(15,2) DEFAULT 0.00,
    per_voucher_tiered JSONB,
    transaction_percentage NUMERIC(5,2) DEFAULT 0.00,
    min_monthly_commitment NUMERIC(15,2) DEFAULT 0.00,
    max_employees_included INTEGER,
    additional_employee_fee NUMERIC(15,2),
    setup_fee NUMERIC(15,2) DEFAULT 0.00,
    features JSONB DEFAULT '{}',
    is_public BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_by UUID,
    CONSTRAINT billing_plans_plan_type_check CHECK (plan_type IN ('subscription', 'pay_as_you_go', 'hybrid')),
    CONSTRAINT billing_plans_monthly_fixed_fee_check CHECK (monthly_fixed_fee >= 0),
    CONSTRAINT billing_plans_per_voucher_fee_check CHECK (per_voucher_fee >= 0),
    CONSTRAINT billing_plans_transaction_percentage_check CHECK (transaction_percentage >= 0),
    CONSTRAINT billing_plans_additional_employee_fee_check CHECK (additional_employee_fee >= 0)
);

-- 3. Users
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
    mfa_secret VARCHAR(255),
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMPTZ,
    email_verification_token VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP,
    deleted_by UUID REFERENCES users(id),
    refresh_token TEXT,
    CONSTRAINT users_status_check CHECK (status IN ('active', 'suspended', 'locked'))
);

-- 4. Merchants
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
    settlement_account_type VARCHAR(50),
    settlement_account_details JSONB,
    settlement_period VARCHAR(50) DEFAULT 'weekly',
    minimum_settlement_amount NUMERIC(15,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT merchants_settlement_period_check CHECK (settlement_period IN ('daily', 'weekly', 'bi_weekly', 'monthly'))
);

-- 5. Voucher Templates
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
    usage_period_limit VARCHAR(50),
    min_purchase_amount NUMERIC(15,2) DEFAULT 0.00,
    is_public_visible BOOLEAN DEFAULT false,
    public_price NUMERIC(15,2),
    public_image_url TEXT,
    terms_and_conditions TEXT,
    background_color VARCHAR(7) DEFAULT '#FFFFFF',
    text_color VARCHAR(7) DEFAULT '#000000',
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT valid_value_for_type CHECK (
        ((voucher_type IN ('fixed_amount', 'open_cash') AND value_amount IS NOT NULL) OR
         (voucher_type = 'percentage' AND percentage_value IS NOT NULL))
    ),
    CONSTRAINT voucher_templates_check CHECK (valid_to >= valid_from),
    CONSTRAINT voucher_templates_percentage_value_check CHECK (percentage_value BETWEEN 0 AND 100)
);

-- 6. Voucher Batches
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
    created_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    CONSTRAINT voucher_batches_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    CONSTRAINT voucher_batches_total_count_check CHECK (total_count > 0)
);

-- 7. Vouchers
CREATE TABLE IF NOT EXISTS vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voucher_template_id UUID NOT NULL REFERENCES voucher_templates(id),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    code VARCHAR(100) NOT NULL UNIQUE,
    qr_code_data TEXT,
    original_value NUMERIC(15,2) NOT NULL,
    remaining_value NUMERIC(15,2) NOT NULL,
    status voucher_status_enum DEFAULT 'active',
    beneficiary_name VARCHAR(255),
    beneficiary_email VARCHAR(255),
    beneficiary_phone VARCHAR(50),
    beneficiary_user_id UUID REFERENCES users(id),
    issued_to_type VARCHAR(50),
    purchase_order_id UUID,
    batch_id UUID REFERENCES voucher_batches(id),
    distribution_method VARCHAR(50),
    distributed_at TIMESTAMPTZ,
    expires_at DATE NOT NULL,
    times_redeemed INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT remaining_value_valid CHECK (remaining_value <= original_value AND remaining_value >= 0),
    CONSTRAINT vouchers_original_value_check CHECK (original_value > 0),
    CONSTRAINT vouchers_distribution_method_check CHECK (distribution_method IN ('print', 'email', 'sms', 'app')),
    CONSTRAINT vouchers_issued_to_type_check CHECK (issued_to_type IN ('employee', 'consumer_gift', 'consumer_self'))
);

-- 8. Purchase Orders
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(100) NOT NULL UNIQUE,
    consumer_id UUID REFERENCES users(id),
    consumer_email VARCHAR(255) NOT NULL,
    consumer_phone VARCHAR(50),
    voucher_template_id UUID NOT NULL REFERENCES voucher_templates(id),
    quantity INTEGER DEFAULT 1,
    unit_price NUMERIC(15,2) NOT NULL,
    subtotal NUMERIC(15,2) NOT NULL,
    fee_amount NUMERIC(15,2) DEFAULT 0.00,
    total_amount NUMERIC(15,2) NOT NULL,
    payment_status payment_status_enum DEFAULT 'pending',
    payment_method VARCHAR(50),
    payment_reference VARCHAR(255),
    payment_metadata JSONB,
    order_type VARCHAR(50) NOT NULL,
    gift_recipient_name VARCHAR(255),
    gift_recipient_email VARCHAR(255),
    gift_recipient_phone VARCHAR(50),
    gift_message TEXT,
    scheduled_delivery_date TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    expiry_notification_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    CONSTRAINT purchase_orders_quantity_check CHECK (quantity > 0),
    CONSTRAINT purchase_orders_subtotal_check CHECK (subtotal >= 0),
    CONSTRAINT purchase_orders_total_amount_check CHECK (total_amount >= 0),
    CONSTRAINT purchase_orders_unit_price_check CHECK (unit_price >= 0),
    CONSTRAINT purchase_orders_fee_amount_check CHECK (fee_amount >= 0),
    CONSTRAINT purchase_orders_order_type_check CHECK (order_type IN ('self', 'gift')),
    CONSTRAINT purchase_orders_payment_method_check CHECK (payment_method IN ('mpesa', 'card', 'bank', 'wallet'))
);

-- 9. Redemptions
CREATE TABLE IF NOT EXISTS redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voucher_id UUID NOT NULL REFERENCES vouchers(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    redeemed_by UUID REFERENCES users(id),
    amount_redeemed NUMERIC(15,2) NOT NULL,
    previous_balance NUMERIC(15,2) NOT NULL,
    new_balance NUMERIC(15,2) NOT NULL,
    redemption_method VARCHAR(50),
    location_data JSONB,
    receipt_number VARCHAR(100),
    terminal_id VARCHAR(100),
    status VARCHAR(50) DEFAULT 'completed',
    reversal_reason TEXT,
    reversed_at TIMESTAMPTZ,
    reversed_by UUID REFERENCES users(id),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    CONSTRAINT redemptions_amount_redeemed_check CHECK (amount_redeemed > 0),
    CONSTRAINT redemptions_redemption_method_check CHECK (redemption_method IN ('code_entry', 'qr_scan', 'phone_lookup', 'nfc')),
    CONSTRAINT redemptions_status_check CHECK (status IN ('completed', 'reversed', 'failed'))
);

-- 10. Gift Deliveries
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
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT gift_deliveries_delivery_method_check CHECK (delivery_method IN ('email', 'sms', 'both')),
    CONSTRAINT gift_deliveries_delivery_status_check CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed'))
);

-- 11. Client Subscriptions
CREATE TABLE IF NOT EXISTS client_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    billing_plan_id UUID NOT NULL REFERENCES billing_plans(id),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,
    custom_rates JSONB,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT client_subscriptions_check CHECK (end_date IS NULL OR end_date >= start_date)
);

-- 12. Invoices
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
    tax_amount NUMERIC(15,2) DEFAULT 0.00,
    tax_rate NUMERIC(5,2) DEFAULT 0.00,
    total_amount NUMERIC(15,2) NOT NULL,
    amount_paid NUMERIC(15,2) DEFAULT 0.00,
    balance_due NUMERIC(15,2) GENERATED ALWAYS AS (total_amount - amount_paid) STORED,
    status invoice_status_enum DEFAULT 'draft',
    payment_method VARCHAR(50),
    payment_reference VARCHAR(255),
    paid_at TIMESTAMPTZ,
    notes TEXT,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT invoices_check CHECK (billing_period_end >= billing_period_start),
    CONSTRAINT invoices_check1 CHECK (due_date >= issue_date),
    CONSTRAINT invoices_subtotal_check CHECK (subtotal >= 0),
    CONSTRAINT invoices_total_amount_check CHECK (total_amount >= 0),
    CONSTRAINT invoices_amount_paid_check CHECK (amount_paid >= 0),
    CONSTRAINT invoices_tax_amount_check CHECK (tax_amount >= 0)
);

-- 13. Settlements
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
    payment_method VARCHAR(50),
    payment_reference VARCHAR(255),
    paid_at TIMESTAMPTZ,
    settlement_report_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CONSTRAINT settlements_check CHECK (period_end >= period_start),
    CONSTRAINT settlements_total_amount_check CHECK (total_amount >= 0),
    CONSTRAINT settlements_rfa_fees_check CHECK (rfa_fees >= 0),
    CONSTRAINT settlements_net_payable_check CHECK (net_payable >= 0),
    CONSTRAINT settlements_total_redemptions_check CHECK (total_redemptions >= 0)
);

-- 14. Transaction Log
CREATE TABLE IF NOT EXISTS transaction_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_type transaction_type_enum NOT NULL,
    transaction_reference VARCHAR(100) UNIQUE,
    source_type VARCHAR(50) NOT NULL,
    source_id UUID NOT NULL,
    from_tenant_id UUID REFERENCES tenants(id),
    to_tenant_id UUID REFERENCES tenants(id),
    from_wallet_before NUMERIC(15,2),
    from_wallet_after NUMERIC(15,2),
    to_wallet_before NUMERIC(15,2),
    to_wallet_after NUMERIC(15,2),
    amount NUMERIC(15,2) NOT NULL,
    fee_amount NUMERIC(15,2) DEFAULT 0.00,
    net_amount NUMERIC(15,2) GENERATED ALWAYS AS (amount - fee_amount) STORED,
    currency VARCHAR(10) DEFAULT 'KES',
    exchange_rate NUMERIC(15,6) DEFAULT 1.0,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    CONSTRAINT transaction_log_amount_check CHECK (amount != 0),
    CONSTRAINT transaction_log_fee_amount_check CHECK (fee_amount >= 0)
);

-- 15. Audit Logs
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
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 16. Voucher Merchant Restrictions
CREATE TABLE IF NOT EXISTS voucher_merchant_restrictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voucher_template_id UUID NOT NULL REFERENCES voucher_templates(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES users(id),
    CONSTRAINT voucher_merchant_restrictions_voucher_template_id_merchant__key UNIQUE (voucher_template_id, merchant_id)
);

-- ============================================================================
-- Create Indexes (for performance)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_users_tenant_role ON users(tenant_id, role);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_reset_token ON users(password_reset_token);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

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
CREATE INDEX IF NOT EXISTS idx_purchase_orders_scheduled ON purchase_orders(scheduled_delivery_date) WHERE scheduled_delivery_date IS NOT NULL AND delivered_at IS NULL;

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

DROP TRIGGER IF EXISTS update_billing_plans_updated_at ON billing_plans;
CREATE TRIGGER update_billing_plans_updated_at BEFORE UPDATE ON billing_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_client_subscriptions_updated_at ON client_subscriptions;
CREATE TRIGGER update_client_subscriptions_updated_at BEFORE UPDATE ON client_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS generate_voucher_code_before_insert ON vouchers;
CREATE TRIGGER generate_voucher_code_before_insert BEFORE INSERT ON vouchers FOR EACH ROW WHEN (NEW.code IS NULL) EXECUTE FUNCTION generate_voucher_code();

DROP TRIGGER IF EXISTS update_voucher_after_redemption ON redemptions;
CREATE TRIGGER update_voucher_after_redemption AFTER INSERT ON redemptions FOR EACH ROW EXECUTE FUNCTION update_voucher_on_redemption();

-- ============================================================================
-- Add Comments (optional but helpful)
-- ============================================================================
COMMENT ON TABLE tenants IS 'Client companies and merchants using the platform';
COMMENT ON COLUMN tenants.wallet_balance IS 'Pre-paid funds available for voucher creation';
COMMENT ON COLUMN tenants.credit_limit IS 'Credit line for post-paid vouchers';

COMMENT ON TABLE users IS 'All system users including internal staff, client users, and consumers';
COMMENT ON COLUMN users.tenant_id IS 'The company/organization this user belongs to';

COMMENT ON TABLE merchants IS 'Physical merchant locations where vouchers can be redeemed';
COMMENT ON COLUMN merchants.settlement_period IS 'How often this merchant gets paid for redemptions';

COMMENT ON TABLE voucher_templates IS 'Template definitions for creating vouchers';
COMMENT ON COLUMN voucher_templates.is_public_visible IS 'If true, appears on public storefront for consumer purchase';

COMMENT ON TABLE vouchers IS 'Individual issued vouchers with unique codes';
COMMENT ON COLUMN vouchers.code IS 'Unique voucher code for redemption';
COMMENT ON COLUMN vouchers.remaining_value IS 'For partial redemptions, tracks remaining balance';
COMMENT ON CONSTRAINT remaining_value_valid ON vouchers IS 'Ensures remaining value never exceeds original';

COMMENT ON TABLE redemptions IS 'Record of each voucher redemption transaction';
COMMENT ON COLUMN redemptions.amount_redeemed IS 'Amount deducted from voucher in this transaction';

COMMENT ON TABLE transaction_log IS 'Complete audit trail for all financial transactions';
COMMENT ON COLUMN transaction_log.source_type IS 'The entity type that triggered this transaction';
COMMENT ON COLUMN transaction_log.source_id IS 'UUID of the source entity';
COMMENT ON COLUMN transaction_log.net_amount IS 'Amount minus fees - actual value transferred';

COMMENT ON TABLE audit_logs IS 'System-wide audit trail for compliance and debugging';
COMMENT ON COLUMN audit_logs.old_values IS 'JSON representation of record before change';
COMMENT ON COLUMN audit_logs.new_values IS 'JSON representation of record after change';