--
-- PostgreSQL database dump
--

\restrict x9cCatN1TrOC1d8RdUuHuB1YBnRrhqdQL99qKph4DwX3T51M6D0OWUnbzYu03In

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-03-10 13:40:25

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE voucherpalace;
--
-- TOC entry 5478 (class 1262 OID 32769)
-- Name: voucherpalace; Type: DATABASE; Schema: -; Owner: keenlenx
--

CREATE DATABASE voucherpalace WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';


ALTER DATABASE voucherpalace OWNER TO keenlenx;

\unrestrict x9cCatN1TrOC1d8RdUuHuB1YBnRrhqdQL99qKph4DwX3T51M6D0OWUnbzYu03In
\connect voucherpalace
\restrict x9cCatN1TrOC1d8RdUuHuB1YBnRrhqdQL99qKph4DwX3T51M6D0OWUnbzYu03In

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5479 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 937 (class 1247 OID 32880)
-- Name: invoice_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.invoice_status_enum AS ENUM (
    'draft',
    'issued',
    'paid',
    'overdue',
    'void'
);


ALTER TYPE public.invoice_status_enum OWNER TO postgres;

--
-- TOC entry 934 (class 1247 OID 32870)
-- Name: payment_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_status_enum AS ENUM (
    'pending',
    'paid',
    'failed',
    'refunded'
);


ALTER TYPE public.payment_status_enum OWNER TO postgres;

--
-- TOC entry 940 (class 1247 OID 32892)
-- Name: settlement_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.settlement_status_enum AS ENUM (
    'pending',
    'processing',
    'paid',
    'failed'
);


ALTER TYPE public.settlement_status_enum OWNER TO postgres;

--
-- TOC entry 919 (class 1247 OID 32820)
-- Name: tenant_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tenant_type_enum AS ENUM (
    'corporate',
    'merchant',
    'rfa_internal'
);


ALTER TYPE public.tenant_type_enum OWNER TO postgres;

--
-- TOC entry 943 (class 1247 OID 32902)
-- Name: transaction_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_type_enum AS ENUM (
    'voucher_creation',
    'redemption',
    'wallet_funding',
    'fee_deduction',
    'settlement',
    'refund'
);


ALTER TYPE public.transaction_type_enum OWNER TO postgres;

--
-- TOC entry 931 (class 1247 OID 32862)
-- Name: usage_limit_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.usage_limit_type_enum AS ENUM (
    'single',
    'multi',
    'unlimited'
);


ALTER TYPE public.usage_limit_type_enum OWNER TO postgres;

--
-- TOC entry 922 (class 1247 OID 32828)
-- Name: user_role_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role_enum AS ENUM (
    'super_admin',
    'client_admin',
    'client_user',
    'merchant_admin',
    'merchant_staff',
    'consumer'
);


ALTER TYPE public.user_role_enum OWNER TO postgres;

--
-- TOC entry 928 (class 1247 OID 32850)
-- Name: voucher_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.voucher_status_enum AS ENUM (
    'active',
    'redeemed',
    'expired',
    'refunded',
    'cancelled'
);


ALTER TYPE public.voucher_status_enum OWNER TO postgres;

--
-- TOC entry 925 (class 1247 OID 32842)
-- Name: voucher_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.voucher_type_enum AS ENUM (
    'fixed_amount',
    'percentage',
    'open_cash'
);


ALTER TYPE public.voucher_type_enum OWNER TO postgres;

--
-- TOC entry 289 (class 1255 OID 33592)
-- Name: generate_voucher_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_voucher_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    prefix VARCHAR(10);
    random_part VARCHAR(20);
    counter INTEGER := 0;
    max_attempts INTEGER := 10;
    code_exists BOOLEAN;
BEGIN
    -- Set prefix based on tenant or type
    prefix := 'RFA-';
    
    -- Generate unique code
    LOOP
        -- Format: RFA-YYYYMMDD-XXXXXXXXXX
        random_part := encode(gen_random_bytes(8), 'hex');
        NEW.code := prefix || to_char(NOW(), 'YYYYMMDD') || '-' || upper(random_part);
        
        -- Check if code already exists
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


ALTER FUNCTION public.generate_voucher_code() OWNER TO postgres;

--
-- TOC entry 284 (class 1255 OID 33581)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 33594)
-- Name: update_voucher_on_redemption(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_voucher_on_redemption() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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


ALTER FUNCTION public.update_voucher_on_redemption() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 236 (class 1259 OID 33555)
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid,
    user_id uuid,
    action character varying(100) NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id uuid,
    old_values jsonb,
    new_values jsonb,
    ip_address inet,
    user_agent text,
    session_id character varying(255),
    request_id character varying(255),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- TOC entry 5480 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE audit_logs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.audit_logs IS 'System-wide audit trail for compliance and debugging';


--
-- TOC entry 5481 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN audit_logs.old_values; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.old_values IS 'JSON representation of record before change';


--
-- TOC entry 5482 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN audit_logs.new_values; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.audit_logs.new_values IS 'JSON representation of record after change';


--
-- TOC entry 231 (class 1259 OID 33333)
-- Name: billing_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.billing_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_name character varying(255) NOT NULL,
    plan_code character varying(50) NOT NULL,
    plan_type character varying(50) NOT NULL,
    description text,
    monthly_fixed_fee numeric(15,2) DEFAULT 0.00,
    per_voucher_fee numeric(15,2) DEFAULT 0.00,
    per_voucher_tiered jsonb,
    transaction_percentage numeric(5,2) DEFAULT 0.00,
    min_monthly_commitment numeric(15,2) DEFAULT 0.00,
    max_employees_included integer,
    additional_employee_fee numeric(15,2),
    setup_fee numeric(15,2) DEFAULT 0.00,
    features jsonb DEFAULT '{}'::jsonb,
    is_public boolean DEFAULT true,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT billing_plans_additional_employee_fee_check CHECK ((additional_employee_fee >= (0)::numeric)),
    CONSTRAINT billing_plans_monthly_fixed_fee_check CHECK ((monthly_fixed_fee >= (0)::numeric)),
    CONSTRAINT billing_plans_per_voucher_fee_check CHECK ((per_voucher_fee >= (0)::numeric)),
    CONSTRAINT billing_plans_plan_type_check CHECK (((plan_type)::text = ANY ((ARRAY['subscription'::character varying, 'pay_as_you_go'::character varying, 'hybrid'::character varying])::text[]))),
    CONSTRAINT billing_plans_transaction_percentage_check CHECK ((transaction_percentage >= (0)::numeric))
);


ALTER TABLE public.billing_plans OWNER TO postgres;

--
-- TOC entry 5483 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE billing_plans; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.billing_plans IS 'Pricing plans for client companies (FR-17)';


--
-- TOC entry 232 (class 1259 OID 33378)
-- Name: client_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    billing_plan_id uuid NOT NULL,
    start_date date NOT NULL,
    end_date date,
    is_active boolean DEFAULT true,
    custom_rates jsonb,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT client_subscriptions_check CHECK (((end_date IS NULL) OR (end_date >= start_date)))
);


ALTER TABLE public.client_subscriptions OWNER TO postgres;

--
-- TOC entry 5484 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE client_subscriptions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.client_subscriptions IS 'Active subscriptions for each client';


--
-- TOC entry 230 (class 1259 OID 33302)
-- Name: gift_deliveries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gift_deliveries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_order_id uuid NOT NULL,
    voucher_id uuid NOT NULL,
    delivery_method character varying(50) NOT NULL,
    recipient_address character varying(255) NOT NULL,
    sent_at timestamp with time zone,
    delivered_at timestamp with time zone,
    opened_at timestamp with time zone,
    delivery_status character varying(50) DEFAULT 'pending'::character varying,
    retry_count integer DEFAULT 0,
    error_message text,
    tracking_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT gift_deliveries_delivery_method_check CHECK (((delivery_method)::text = ANY ((ARRAY['email'::character varying, 'sms'::character varying, 'both'::character varying])::text[]))),
    CONSTRAINT gift_deliveries_delivery_status_check CHECK (((delivery_status)::text = ANY ((ARRAY['pending'::character varying, 'sent'::character varying, 'delivered'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.gift_deliveries OWNER TO postgres;

--
-- TOC entry 5485 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE gift_deliveries; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.gift_deliveries IS 'Track delivery of gifted vouchers to recipients';


--
-- TOC entry 233 (class 1259 OID 33416)
-- Name: invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_number character varying(100) NOT NULL,
    tenant_id uuid NOT NULL,
    billing_period_start date NOT NULL,
    billing_period_end date NOT NULL,
    issue_date date NOT NULL,
    due_date date NOT NULL,
    items jsonb NOT NULL,
    subtotal numeric(15,2) NOT NULL,
    tax_amount numeric(15,2) DEFAULT 0.00,
    tax_rate numeric(5,2) DEFAULT 0.00,
    total_amount numeric(15,2) NOT NULL,
    amount_paid numeric(15,2) DEFAULT 0.00,
    balance_due numeric(15,2) GENERATED ALWAYS AS ((total_amount - amount_paid)) STORED,
    status public.invoice_status_enum DEFAULT 'draft'::public.invoice_status_enum,
    payment_method character varying(50),
    payment_reference character varying(255),
    paid_at timestamp with time zone,
    notes text,
    pdf_url text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT invoices_amount_paid_check CHECK ((amount_paid >= (0)::numeric)),
    CONSTRAINT invoices_check CHECK ((billing_period_end >= billing_period_start)),
    CONSTRAINT invoices_check1 CHECK ((due_date >= issue_date)),
    CONSTRAINT invoices_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT invoices_tax_amount_check CHECK ((tax_amount >= (0)::numeric)),
    CONSTRAINT invoices_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


ALTER TABLE public.invoices OWNER TO postgres;

--
-- TOC entry 5486 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE invoices; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.invoices IS 'Monthly invoices for client companies (FR-22, FR-23)';


--
-- TOC entry 5487 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN invoices.items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.invoices.items IS 'JSON array of line items: description, quantity, rate, amount';


--
-- TOC entry 223 (class 1259 OID 32992)
-- Name: merchants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.merchants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    merchant_name character varying(255) NOT NULL,
    merchant_code character varying(50),
    merchant_category character varying(100),
    contact_person character varying(255),
    email character varying(255),
    phone character varying(50),
    address text,
    latitude numeric(10,8),
    longitude numeric(11,8),
    operating_hours jsonb,
    settlement_account_type character varying(50),
    settlement_account_details jsonb,
    settlement_period character varying(50) DEFAULT 'weekly'::character varying,
    minimum_settlement_amount numeric(15,2) DEFAULT 0.00,
    is_active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT merchants_settlement_period_check CHECK (((settlement_period)::text = ANY ((ARRAY['daily'::character varying, 'weekly'::character varying, 'bi_weekly'::character varying, 'monthly'::character varying])::text[])))
);


ALTER TABLE public.merchants OWNER TO postgres;

--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE merchants; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.merchants IS 'Physical merchant locations where vouchers can be redeemed';


--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN merchants.settlement_period; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.merchants.settlement_period IS 'How often this merchant gets paid for redemptions (FR-12)';


--
-- TOC entry 229 (class 1259 OID 33253)
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.purchase_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_number character varying(100) NOT NULL,
    consumer_id uuid,
    consumer_email character varying(255) NOT NULL,
    consumer_phone character varying(50),
    voucher_template_id uuid NOT NULL,
    quantity integer DEFAULT 1,
    unit_price numeric(15,2) NOT NULL,
    subtotal numeric(15,2) NOT NULL,
    fee_amount numeric(15,2) DEFAULT 0.00,
    total_amount numeric(15,2) NOT NULL,
    payment_status public.payment_status_enum DEFAULT 'pending'::public.payment_status_enum,
    payment_method character varying(50),
    payment_reference character varying(255),
    payment_metadata jsonb,
    order_type character varying(50) NOT NULL,
    gift_recipient_name character varying(255),
    gift_recipient_email character varying(255),
    gift_recipient_phone character varying(50),
    gift_message text,
    scheduled_delivery_date timestamp with time zone,
    delivered_at timestamp with time zone,
    expiry_notification_sent boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT purchase_orders_fee_amount_check CHECK ((fee_amount >= (0)::numeric)),
    CONSTRAINT purchase_orders_order_type_check CHECK (((order_type)::text = ANY ((ARRAY['self'::character varying, 'gift'::character varying])::text[]))),
    CONSTRAINT purchase_orders_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['mpesa'::character varying, 'card'::character varying, 'bank'::character varying, 'wallet'::character varying])::text[]))),
    CONSTRAINT purchase_orders_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT purchase_orders_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT purchase_orders_total_amount_check CHECK ((total_amount >= (0)::numeric)),
    CONSTRAINT purchase_orders_unit_price_check CHECK ((unit_price >= (0)::numeric))
);


ALTER TABLE public.purchase_orders OWNER TO postgres;

--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE purchase_orders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.purchase_orders IS 'Consumer purchases from public storefront (FR-28, FR-29)';


--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN purchase_orders.order_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.purchase_orders.order_type IS 'Self purchase or gift for someone else';


--
-- TOC entry 228 (class 1259 OID 33205)
-- Name: redemptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.redemptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    voucher_id uuid NOT NULL,
    merchant_id uuid NOT NULL,
    redeemed_by uuid,
    amount_redeemed numeric(15,2) NOT NULL,
    previous_balance numeric(15,2) NOT NULL,
    new_balance numeric(15,2) NOT NULL,
    redemption_method character varying(50),
    location_data jsonb,
    receipt_number character varying(100),
    terminal_id character varying(100),
    status character varying(50) DEFAULT 'completed'::character varying,
    reversal_reason text,
    reversed_at timestamp with time zone,
    reversed_by uuid,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT redemptions_amount_redeemed_check CHECK ((amount_redeemed > (0)::numeric)),
    CONSTRAINT redemptions_redemption_method_check CHECK (((redemption_method)::text = ANY ((ARRAY['code_entry'::character varying, 'qr_scan'::character varying, 'phone_lookup'::character varying, 'nfc'::character varying])::text[]))),
    CONSTRAINT redemptions_status_check CHECK (((status)::text = ANY ((ARRAY['completed'::character varying, 'reversed'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.redemptions OWNER TO postgres;

--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE redemptions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.redemptions IS 'Record of each voucher redemption transaction (FR-07, FR-10)';


--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN redemptions.amount_redeemed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.redemptions.amount_redeemed IS 'Amount deducted from voucher in this transaction';


--
-- TOC entry 234 (class 1259 OID 33467)
-- Name: settlements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settlements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    settlement_number character varying(100) NOT NULL,
    merchant_id uuid NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    total_redemptions integer DEFAULT 0 NOT NULL,
    total_amount numeric(15,2) NOT NULL,
    rfa_fees numeric(15,2) NOT NULL,
    net_payable numeric(15,2) NOT NULL,
    status public.settlement_status_enum DEFAULT 'pending'::public.settlement_status_enum,
    payment_method character varying(50),
    payment_reference character varying(255),
    paid_at timestamp with time zone,
    settlement_report_url text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT settlements_check CHECK ((period_end >= period_start)),
    CONSTRAINT settlements_net_payable_check CHECK ((net_payable >= (0)::numeric)),
    CONSTRAINT settlements_rfa_fees_check CHECK ((rfa_fees >= (0)::numeric)),
    CONSTRAINT settlements_total_amount_check CHECK ((total_amount >= (0)::numeric)),
    CONSTRAINT settlements_total_redemptions_check CHECK ((total_redemptions >= 0))
);


ALTER TABLE public.settlements OWNER TO postgres;

--
-- TOC entry 5494 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE settlements; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.settlements IS 'Settlement payments to merchants (FR-13, FR-30)';


--
-- TOC entry 221 (class 1259 OID 32915)
-- Name: tenants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_name character varying(255) NOT NULL,
    tenant_type public.tenant_type_enum NOT NULL,
    registration_number character varying(100),
    tax_id character varying(100),
    email character varying(255),
    phone character varying(50),
    address text,
    website character varying(255),
    logo_url text,
    status character varying(50) DEFAULT 'active'::character varying,
    subscription_plan_id uuid,
    wallet_balance numeric(15,2) DEFAULT 0.00,
    credit_limit numeric(15,2) DEFAULT 0.00,
    billing_cycle character varying(50) DEFAULT 'monthly'::character varying,
    settings jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT tenants_billing_cycle_check CHECK (((billing_cycle)::text = ANY ((ARRAY['monthly'::character varying, 'quarterly'::character varying, 'annual'::character varying])::text[]))),
    CONSTRAINT tenants_credit_limit_check CHECK ((credit_limit >= (0)::numeric)),
    CONSTRAINT tenants_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'suspended'::character varying, 'pending'::character varying])::text[]))),
    CONSTRAINT tenants_wallet_balance_check CHECK ((wallet_balance >= (0)::numeric))
);


ALTER TABLE public.tenants OWNER TO postgres;

--
-- TOC entry 5495 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE tenants; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.tenants IS 'Client companies and merchants using the platform';


--
-- TOC entry 5496 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN tenants.wallet_balance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tenants.wallet_balance IS 'Pre-paid funds available for voucher creation';


--
-- TOC entry 5497 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN tenants.credit_limit; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tenants.credit_limit IS 'Credit line for post-paid vouchers';


--
-- TOC entry 235 (class 1259 OID 33513)
-- Name: transaction_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_type public.transaction_type_enum NOT NULL,
    transaction_reference character varying(100),
    source_type character varying(50) NOT NULL,
    source_id uuid NOT NULL,
    from_tenant_id uuid,
    to_tenant_id uuid,
    from_wallet_before numeric(15,2),
    from_wallet_after numeric(15,2),
    to_wallet_before numeric(15,2),
    to_wallet_after numeric(15,2),
    amount numeric(15,2) NOT NULL,
    fee_amount numeric(15,2) DEFAULT 0.00,
    net_amount numeric(15,2) GENERATED ALWAYS AS ((amount - fee_amount)) STORED,
    currency character varying(10) DEFAULT 'KES'::character varying,
    exchange_rate numeric(15,6) DEFAULT 1.0,
    description text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT transaction_log_amount_check CHECK ((amount <> (0)::numeric)),
    CONSTRAINT transaction_log_fee_amount_check CHECK ((fee_amount >= (0)::numeric))
);


ALTER TABLE public.transaction_log OWNER TO postgres;

--
-- TOC entry 5498 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE transaction_log; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.transaction_log IS 'Complete audit trail for all financial transactions';


--
-- TOC entry 5499 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN transaction_log.source_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.transaction_log.source_type IS 'The entity type that triggered this transaction';


--
-- TOC entry 5500 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN transaction_log.source_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.transaction_log.source_id IS 'UUID of the source entity';


--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN transaction_log.net_amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.transaction_log.net_amount IS 'Amount minus fees - actual value transferred';


--
-- TOC entry 222 (class 1259 OID 32940)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    phone character varying(50),
    role public.user_role_enum NOT NULL,
    is_email_verified boolean DEFAULT false,
    is_phone_verified boolean DEFAULT false,
    last_login_at timestamp with time zone,
    preferences jsonb DEFAULT '{}'::jsonb,
    status character varying(50) DEFAULT 'active'::character varying,
    mfa_enabled boolean DEFAULT false,
    mfa_secret character varying(255),
    password_reset_token character varying(255),
    password_reset_expires timestamp with time zone,
    email_verification_token character varying(255),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    deleted_at timestamp without time zone,
    deleted_by uuid,
    refresh_token text,
    CONSTRAINT users_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'suspended'::character varying, 'locked'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 5502 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.users IS 'All system users including internal staff, client users, merchants, and consumers';


--
-- TOC entry 5503 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN users.tenant_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.tenant_id IS 'The company/organization this user belongs to';


--
-- TOC entry 226 (class 1259 OID 33103)
-- Name: voucher_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.voucher_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    batch_reference character varying(100) NOT NULL,
    voucher_template_id uuid NOT NULL,
    total_count integer NOT NULL,
    successful_count integer DEFAULT 0,
    failed_count integer DEFAULT 0,
    source_file_url text,
    status character varying(50) DEFAULT 'pending'::character varying,
    error_log text,
    processing_started_at timestamp with time zone,
    processing_completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT voucher_batches_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying])::text[]))),
    CONSTRAINT voucher_batches_total_count_check CHECK ((total_count > 0))
);


ALTER TABLE public.voucher_batches OWNER TO postgres;

--
-- TOC entry 5504 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE voucher_batches; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.voucher_batches IS 'Track bulk voucher creation jobs (FR-02)';


--
-- TOC entry 225 (class 1259 OID 33075)
-- Name: voucher_merchant_restrictions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.voucher_merchant_restrictions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    voucher_template_id uuid NOT NULL,
    merchant_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid
);


ALTER TABLE public.voucher_merchant_restrictions OWNER TO postgres;

--
-- TOC entry 5505 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE voucher_merchant_restrictions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.voucher_merchant_restrictions IS 'Many-to-many relationship for merchant acceptance (FR-03)';


--
-- TOC entry 224 (class 1259 OID 33030)
-- Name: voucher_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.voucher_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    template_name character varying(255) NOT NULL,
    description text,
    voucher_type public.voucher_type_enum NOT NULL,
    value_amount numeric(15,2),
    percentage_value numeric(5,2),
    valid_from date,
    valid_to date,
    usage_limit_type public.usage_limit_type_enum DEFAULT 'single'::public.usage_limit_type_enum,
    usage_limit_count integer,
    usage_period_limit character varying(50),
    min_purchase_amount numeric(15,2) DEFAULT 0.00,
    is_public_visible boolean DEFAULT false,
    public_price numeric(15,2),
    public_image_url text,
    terms_and_conditions text,
    background_color character varying(7) DEFAULT '#FFFFFF'::character varying,
    text_color character varying(7) DEFAULT '#000000'::character varying,
    is_active boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT valid_value_for_type CHECK ((((voucher_type = ANY (ARRAY['fixed_amount'::public.voucher_type_enum, 'open_cash'::public.voucher_type_enum])) AND (value_amount IS NOT NULL)) OR ((voucher_type = 'percentage'::public.voucher_type_enum) AND (percentage_value IS NOT NULL)))),
    CONSTRAINT voucher_templates_check CHECK ((valid_to >= valid_from)),
    CONSTRAINT voucher_templates_percentage_value_check CHECK (((percentage_value >= (0)::numeric) AND (percentage_value <= (100)::numeric))),
    CONSTRAINT voucher_templates_usage_period_limit_check CHECK (((usage_period_limit)::text = ANY ((ARRAY['daily'::character varying, 'weekly'::character varying, 'monthly'::character varying, NULL::character varying])::text[])))
);


ALTER TABLE public.voucher_templates OWNER TO postgres;

--
-- TOC entry 5506 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE voucher_templates; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.voucher_templates IS 'Template definitions for creating vouchers (FR-03)';


--
-- TOC entry 5507 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN voucher_templates.is_public_visible; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.voucher_templates.is_public_visible IS 'If true, appears on public storefront for consumer purchase';


--
-- TOC entry 227 (class 1259 OID 33141)
-- Name: vouchers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vouchers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    voucher_template_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    code character varying(100) NOT NULL,
    qr_code_data text,
    original_value numeric(15,2) NOT NULL,
    remaining_value numeric(15,2) NOT NULL,
    status public.voucher_status_enum DEFAULT 'active'::public.voucher_status_enum,
    beneficiary_name character varying(255),
    beneficiary_email character varying(255),
    beneficiary_phone character varying(50),
    beneficiary_user_id uuid,
    issued_to_type character varying(50),
    purchase_order_id uuid,
    batch_id uuid,
    distribution_method character varying(50),
    distributed_at timestamp with time zone,
    expires_at date NOT NULL,
    times_redeemed integer DEFAULT 0,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    CONSTRAINT remaining_value_valid CHECK ((remaining_value <= original_value)),
    CONSTRAINT vouchers_distribution_method_check CHECK (((distribution_method)::text = ANY ((ARRAY['print'::character varying, 'email'::character varying, 'sms'::character varying, 'app'::character varying])::text[]))),
    CONSTRAINT vouchers_issued_to_type_check CHECK (((issued_to_type)::text = ANY ((ARRAY['employee'::character varying, 'consumer_gift'::character varying, 'consumer_self'::character varying])::text[]))),
    CONSTRAINT vouchers_original_value_check CHECK ((original_value > (0)::numeric)),
    CONSTRAINT vouchers_remaining_value_check CHECK ((remaining_value >= (0)::numeric))
);


ALTER TABLE public.vouchers OWNER TO postgres;

--
-- TOC entry 5508 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE vouchers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.vouchers IS 'Individual issued vouchers with unique codes (FR-04)';


--
-- TOC entry 5509 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN vouchers.code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vouchers.code IS 'Unique voucher code for redemption';


--
-- TOC entry 5510 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN vouchers.remaining_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vouchers.remaining_value IS 'For partial redemptions, tracks remaining balance';


--
-- TOC entry 5511 (class 0 OID 0)
-- Dependencies: 227
-- Name: CONSTRAINT remaining_value_valid ON vouchers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT remaining_value_valid ON public.vouchers IS 'Ensures remaining value never exceeds original';


--
-- TOC entry 5472 (class 0 OID 33555)
-- Dependencies: 236
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5467 (class 0 OID 33333)
-- Dependencies: 231
-- Data for Name: billing_plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.billing_plans VALUES ('22222222-2222-2222-2222-222222222221', 'Starter', 'STARTER', 'pay_as_you_go', 'Pay only for what you use', 0.00, 0.50, NULL, 2.00, 0.00, NULL, NULL, 0.00, '{"reports": "basic", "max_users": 5}', true, true, '2026-02-17 22:30:14.459984+03', '2026-02-17 22:30:14.459984+03', '33333333-3333-3333-3333-333333333333', NULL);
INSERT INTO public.billing_plans VALUES ('22222222-2222-2222-2222-222222222222', 'Professional', 'PRO', 'hybrid', 'For growing businesses', 49.00, 0.25, NULL, 1.50, 0.00, NULL, NULL, 0.00, '{"reports": "advanced", "max_users": 20, "api_access": true}', true, true, '2026-02-17 22:30:14.459984+03', '2026-02-17 22:30:14.459984+03', '33333333-3333-3333-3333-333333333333', NULL);
INSERT INTO public.billing_plans VALUES ('22222222-2222-2222-2222-222222222223', 'Enterprise', 'ENTERPRISE', 'subscription', 'Custom solutions for large organizations', 199.00, 0.10, NULL, 1.00, 0.00, NULL, NULL, 0.00, '{"reports": "custom", "max_users": -1, "api_access": true, "dedicated_support": true}', true, true, '2026-02-17 22:30:14.459984+03', '2026-02-17 22:30:14.459984+03', '33333333-3333-3333-3333-333333333333', NULL);


--
-- TOC entry 5468 (class 0 OID 33378)
-- Dependencies: 232
-- Data for Name: client_subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5466 (class 0 OID 33302)
-- Dependencies: 230
-- Data for Name: gift_deliveries; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5469 (class 0 OID 33416)
-- Dependencies: 233
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5459 (class 0 OID 32992)
-- Dependencies: 223
-- Data for Name: merchants; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.merchants VALUES ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '11111111-1111-1111-1111-111111111111', 'Test Restaurant', 'TEST001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'weekly', 0.00, true, '{}', '2026-02-18 02:53:15.057811+03', '2026-02-18 02:53:15.057811+03', NULL, NULL);
INSERT INTO public.merchants VALUES ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Java House', 'JAVA01', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'weekly', 0.00, true, '{}', '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', NULL, NULL);
INSERT INTO public.merchants VALUES ('a0000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'KFC', 'KFC01', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'weekly', 0.00, true, '{}', '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', NULL, NULL);


--
-- TOC entry 5465 (class 0 OID 33253)
-- Dependencies: 229
-- Data for Name: purchase_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5464 (class 0 OID 33205)
-- Dependencies: 228
-- Data for Name: redemptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.redemptions VALUES ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 500.00, 500.00, 0.00, NULL, NULL, NULL, NULL, 'completed', NULL, NULL, NULL, '{}', '2026-02-18 03:17:16.661252+03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1');
INSERT INTO public.redemptions VALUES ('542ef255-ce25-4f03-b158-0528ab0b7318', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', 'a0000000-0000-0000-0000-000000000001', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 50.00, 100.00, 50.00, NULL, NULL, 'REC-001', NULL, 'completed', NULL, NULL, NULL, '{}', '2026-02-18 03:26:55.381245+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb');
INSERT INTO public.redemptions VALUES ('8477c470-bcea-45be-bf6d-f1c6cafeddeb', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', 'a0000000-0000-0000-0000-000000000001', NULL, 50.00, 50.00, 0.00, 'qr_scan', NULL, 'RCP20260219001', NULL, 'completed', NULL, NULL, NULL, '{}', '2026-03-09 22:22:51.961929+03', '1ee87751-8c00-4bde-a199-3756fa5682b3');


--
-- TOC entry 5470 (class 0 OID 33467)
-- Dependencies: 234
-- Data for Name: settlements; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5457 (class 0 OID 32915)
-- Dependencies: 221
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tenants VALUES ('11111111-1111-1111-1111-111111111111', 'Romeo Fox Alpha Limited', 'rfa_internal', NULL, NULL, 'system@romeofoxalpha.com', NULL, NULL, NULL, NULL, 'active', NULL, 0.00, 0.00, 'monthly', '{}', true, '2026-02-17 22:30:14.459984+03', '2026-02-17 22:30:14.459984+03', '33333333-3333-3333-3333-333333333333', NULL);
INSERT INTO public.tenants VALUES ('22222222-2222-2222-2222-222222222222', 'Kenya Airways', 'corporate', NULL, NULL, 'hr@kenya-airways.com', NULL, NULL, NULL, NULL, 'active', NULL, 0.00, 0.00, 'monthly', '{}', true, '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', NULL, NULL);
INSERT INTO public.tenants VALUES ('3e0d8385-9c7a-4462-a009-63fdd514da8e', 'Kool Cutz', 'corporate', '', '', 'info@koolcutz.com', '0724727181', '', NULL, NULL, 'active', NULL, 0.00, 0.00, 'monthly', '{}', true, '2026-03-05 02:56:01.603296+03', '2026-03-05 02:56:01.603296+03', NULL, NULL);
INSERT INTO public.tenants VALUES ('b1e04148-1c41-415f-992c-8aacddb4498a', 'National Bank', 'corporate', 'REG123456', 'TAX123456', 'info@nbk.com', '0702000222', 'string', 'https://www.abccorp.com', NULL, 'active', NULL, 0.00, 0.00, 'monthly', '{}', true, '2026-02-19 03:01:39.115798+03', '2026-03-05 05:54:50.203557+03', NULL, NULL);
INSERT INTO public.tenants VALUES ('6cba5fa0-2099-4c33-9157-8773ebf756de', 'Hot Foods', 'merchant', NULL, NULL, 'info@hotfoods.com', '0768908987', NULL, NULL, NULL, 'active', NULL, 0.00, 0.00, 'monthly', '{}', true, '2026-03-10 04:34:30.906846+03', '2026-03-10 04:34:30.906846+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);


--
-- TOC entry 5471 (class 0 OID 33513)
-- Dependencies: 235
-- Data for Name: transaction_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.transaction_log VALUES ('ed814b5d-ffce-4ddf-a404-e697fb39200d', 'redemption', NULL, 'redemption', 'f0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', NULL, NULL, NULL, NULL, 500.00, 0.00, DEFAULT, 'KES', 1.000000, 'Voucher redemption at merchant', '{}', '2026-02-18 03:17:16.661252+03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1');
INSERT INTO public.transaction_log VALUES ('e9302f26-acde-4503-851c-8d0c7113b324', 'redemption', NULL, 'redemption', '542ef255-ce25-4f03-b158-0528ab0b7318', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', NULL, NULL, NULL, NULL, 50.00, 0.00, DEFAULT, 'KES', 1.000000, 'Voucher redemption at merchant', '{}', '2026-02-18 03:26:55.381245+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb');
INSERT INTO public.transaction_log VALUES ('a44dce3b-4aae-4c8a-b838-4cdfe9ecfdc1', 'redemption', NULL, 'redemption', '8477c470-bcea-45be-bf6d-f1c6cafeddeb', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', NULL, NULL, NULL, NULL, 50.00, 0.00, DEFAULT, 'KES', 1.000000, 'Voucher redemption at merchant', '{}', '2026-03-09 22:22:51.961929+03', '1ee87751-8c00-4bde-a199-3756fa5682b3');


--
-- TOC entry 5458 (class 0 OID 32940)
-- Dependencies: 222
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES ('dabf03af-a6fa-46c5-aaea-01c7a99bbc13', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'keeenlenx@gmail.com', '$2b$10$YOXeYg1pnHBN2KF3rmvI7uxjLPkbzFHikxmqtcFSA7xa4gk9BqHOW', 'keenlenx', 'ndiwa', '0713820049', 'consumer', false, false, '2026-03-05 05:27:32.742+03', '{}', 'active', false, NULL, NULL, NULL, NULL, '2026-03-05 02:46:09.271414+03', '2026-03-05 05:27:32.743962+03', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.users VALUES ('186243ed-75de-4133-931d-f9091c67580e', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'john@example.com', '$2b$10$GuDmHeGKRvBGjOeZggHiC.lei7rQl.XiaK2grJodTZt2lcb0q5pui', 'John', 'Doe', '712345678', 'consumer', false, false, NULL, '{}', 'active', false, NULL, NULL, NULL, NULL, '2026-03-10 04:20:11.46478+03', '2026-03-10 04:20:11.46478+03', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.users VALUES ('d18b1d25-1ceb-4a56-a5e6-16476c4fb514', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'jane@example.com', '$2b$10$l1Bu65l4snFFkTeb4U.BHOky3AWRB0c9WIOjEFk5aBSKKoVhTnNDi', 'Jane', 'Smith', '798765432', 'client_admin', false, false, NULL, '{}', 'active', false, NULL, NULL, NULL, NULL, '2026-03-10 04:20:11.628223+03', '2026-03-10 04:20:11.628223+03', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.users VALUES ('98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', '11111111-1111-1111-1111-111111111111', 'brianndiwa@gmail.com', '$2b$10$O8Ss9F5T9ZEXnUdqf.SQy.02dnd/bqvsCdE8Pm6wCi52cUTLU7M8G', 'Brian', 'Ndiwa', '+254704611605', 'client_admin', false, false, '2026-03-10 04:50:45.49+03', '{}', 'active', false, NULL, NULL, NULL, NULL, '2026-02-18 02:16:15.352161+03', '2026-03-10 04:50:45.491116+03', NULL, NULL, NULL, NULL, 'd1bac3da63ecf865d59a5a8988e2d0c46f9ecc95efc3bb43e68dcc00baf6b99591ce3100bbb07e0f');
INSERT INTO public.users VALUES ('1ee87751-8c00-4bde-a199-3756fa5682b3', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'bdiwa@gmail.com', '$2b$10$O8Ss9F5T9ZEXnUdqf.SQy.02dnd/bqvsCdE8Pm6wCi52cUTLU7M8G', 'Brian', 'K', '0704611605', 'consumer', false, false, '2026-03-10 11:02:26.265+03', '{}', 'active', false, NULL, NULL, NULL, NULL, '2026-03-05 01:55:56.609712+03', '2026-03-10 11:02:26.267805+03', NULL, NULL, NULL, NULL, '8ab9e553d5375e2bee4493332fbd431b4b23e14319b4a99891afb90519ba741e308ec66cae8bd406');
INSERT INTO public.users VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', 'admin@safaricom.co.ke', '$2a$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'John', 'Kamau', NULL, 'client_admin', false, false, NULL, '{}', 'active', false, NULL, NULL, NULL, NULL, '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.users VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '22222222-2222-2222-2222-222222222222', 'admin@kenya-airways.com', '$2a$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'Sarah', 'Odhiambo', NULL, 'client_admin', false, false, NULL, '{}', 'active', false, NULL, NULL, NULL, NULL, '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.users VALUES ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'admin@romeofoxalpha.com', '$2y$10$F9yb/1Z2wfXbC/42Ug1AnefOvZxmyx37va5IRBulhomX0COjOENvi', 'System', 'Administrator', NULL, 'super_admin', true, false, '2026-02-18 04:32:08.955029+03', '{}', 'active', false, NULL, NULL, NULL, NULL, '2026-02-17 22:30:14.459984+03', '2026-02-18 04:32:08.955029+03', NULL, NULL, NULL, NULL, NULL);


--
-- TOC entry 5462 (class 0 OID 33103)
-- Dependencies: 226
-- Data for Name: voucher_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.voucher_batches VALUES ('b5080460-6d5e-4b6f-b1e9-8fbc8fd74eb5', '11111111-1111-1111-1111-111111111111', 'BATCH-69963548aac4e9.22358771', 'f3b6eef4-312a-472e-b59a-90f47835608b', 2, 2, 0, NULL, 'completed', NULL, NULL, NULL, '2026-02-19 00:55:20.739924+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb');
INSERT INTO public.voucher_batches VALUES ('c49a2364-15b0-41b6-b6b5-649dac7fc022', '11111111-1111-1111-1111-111111111111', 'BATCH-69963bb1b111c3.12283103', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 2, 0, 2, NULL, 'failed', NULL, NULL, NULL, '2026-02-19 01:22:41.738868+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb');
INSERT INTO public.voucher_batches VALUES ('79426782-5748-455f-867e-c5de2fefe13e', '11111111-1111-1111-1111-111111111111', 'BATCH-69963bb2333082.84148398', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 2, 0, 2, NULL, 'failed', NULL, NULL, NULL, '2026-02-19 01:22:42.214557+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb');
INSERT INTO public.voucher_batches VALUES ('9ab4ba1f-0f35-4b20-a5db-115fd63b7842', '11111111-1111-1111-1111-111111111111', '5c336de9-efb3-41cc-ba85-6e1640aa9b15', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 2, 0, 2, NULL, 'failed', NULL, NULL, NULL, '2026-02-19 01:28:26.660362+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb');
INSERT INTO public.voucher_batches VALUES ('6337f4bb-c4d1-4106-8a0d-884371056141', '11111111-1111-1111-1111-111111111111', 'c328b51a-406a-461c-b90c-2431a04bf72e', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 2, 0, 0, NULL, 'processing', NULL, NULL, NULL, '2026-02-19 01:30:28.68208+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb');
INSERT INTO public.voucher_batches VALUES ('57499418-70ef-41ff-b01e-a4e9c7364037', '11111111-1111-1111-1111-111111111111', 'BATCH-69963df9e89151.31706787', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 2, 0, 0, NULL, 'processing', NULL, NULL, NULL, '2026-02-19 01:32:25.954722+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb');
INSERT INTO public.voucher_batches VALUES ('6539da47-c266-4a37-910e-eec6a8b46696', '11111111-1111-1111-1111-111111111111', 'BATCH-1771459552687-7e5b32be', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 2, 0, 0, NULL, 'processing', NULL, NULL, NULL, '2026-02-19 03:05:52.735619+03', NULL);
INSERT INTO public.voucher_batches VALUES ('7f443cc1-68bc-4b24-b417-807a8efc6b81', '11111111-1111-1111-1111-111111111111', 'BATCH-1771459990036-1a0cf1d0', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 2, 2, 0, NULL, 'completed', NULL, '2026-02-19 03:13:10.101229+03', '2026-02-19 03:13:10.202443+03', '2026-02-19 03:13:10.101229+03', NULL);


--
-- TOC entry 5461 (class 0 OID 33075)
-- Dependencies: 225
-- Data for Name: voucher_merchant_restrictions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5460 (class 0 OID 33030)
-- Dependencies: 224
-- Data for Name: voucher_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.voucher_templates VALUES ('77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'Test Voucher', NULL, 'fixed_amount', 100.00, NULL, '2026-02-18', '2026-03-20', 'single', NULL, NULL, 0.00, false, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 02:53:15.057811+03', '2026-02-18 02:53:15.057811+03', '33333333-3333-3333-3333-333333333333', NULL);
INSERT INTO public.voucher_templates VALUES ('d0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Staff Lunch', NULL, 'fixed_amount', 500.00, NULL, '2026-02-18', '2026-05-19', 'single', NULL, NULL, 0.00, false, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL);
INSERT INTO public.voucher_templates VALUES ('d0000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Crew Meal', NULL, 'fixed_amount', 750.00, NULL, '2026-02-18', '2026-04-19', 'single', NULL, NULL, 0.00, false, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL);
INSERT INTO public.voucher_templates VALUES ('f1fe0116-4617-4fc7-a567-3a556278c0cd', '11111111-1111-1111-1111-111111111111', 'Tradwinds Lunch Voucher', 'KSH 300 voucher', 'fixed_amount', 300.00, 0.00, '2026-02-01', '2026-12-31', 'multi', 1, NULL, 50.00, true, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 04:03:47.750102+03', '2026-02-18 04:03:47.750102+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.voucher_templates VALUES ('e02c2081-5e4c-4305-8fa3-0f7645dd15e8', '11111111-1111-1111-1111-111111111111', 'Tradewinds Lunch Voucher', 'KSH 300 voucher', 'fixed_amount', 300.00, 0.00, '2026-02-01', '2026-12-31', 'multi', NULL, NULL, 0.00, true, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 04:05:31.02053+03', '2026-02-18 04:05:31.02053+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.voucher_templates VALUES ('130a46d6-bfa1-4ee8-b549-0589be29448b', '11111111-1111-1111-1111-111111111111', 'Staff Lunch Voucher', 'Daily lunch at partner restaurants', 'fixed_amount', 500.00, 20.00, '2024-01-01', '2024-12-31', 'single', 5, NULL, 100.00, NULL, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 14:34:38.475133+03', '2026-02-18 14:34:38.475133+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.voucher_templates VALUES ('f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'Staff Lunch Voucher', 'Daily lunch at partner restaurants', 'fixed_amount', 500.00, 20.00, '2024-01-01', '2024-12-31', 'single', 5, NULL, 100.00, true, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 14:46:18.688894+03', '2026-02-18 14:46:18.688894+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.voucher_templates VALUES ('f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'Tradwinds Lunch Voucher', 'KSH 300 voucher', 'open_cash', 300.00, 0.00, '2026-02-01', '2026-12-31', 'multi', 1, NULL, 50.00, true, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 04:03:58.714579+03', '2026-03-05 04:21:57.607769+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.voucher_templates VALUES ('eba70e22-b0e7-43f5-aa68-21369c7e263b', '11111111-1111-1111-1111-111111111111', 'Holiday Special', '20% off holiday discount', 'percentage', 100.00, 0.00, '2024-12-01', '2024-12-31', 'single', 5, NULL, 50.00, true, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 03:22:03.100773+03', '2026-03-05 04:22:41.684142+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.voucher_templates VALUES ('1290a50b-1c09-44dd-8935-b96ff12dd25a', '11111111-1111-1111-1111-111111111111', 'Holiday Special', '20% off holiday discount', 'fixed_amount', 100.00, 0.00, '2024-12-01', '2024-12-31', 'single', 5, NULL, 50.00, true, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-02-18 03:22:35.854235+03', '2026-03-05 04:22:41.686875+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.voucher_templates VALUES ('4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'Holiday Discount', '500 National Bank Lunch', 'fixed_amount', 500.00, 0.00, '2026-01-01', '2026-12-31', 'multi', NULL, NULL, 0.00, true, 500.00, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-03-09 22:26:03.958236+03', '2026-03-09 22:26:03.958236+03', NULL, NULL);
INSERT INTO public.voucher_templates VALUES ('aa32a1e2-e44d-4cad-977d-e5c9865ad13a', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'NAtional  lunch 500', NULL, 'fixed_amount', 500.00, NULL, NULL, NULL, 'single', NULL, NULL, 0.00, false, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-03-10 03:21:01.570259+03', '2026-03-10 03:21:01.570259+03', NULL, NULL);
INSERT INTO public.voucher_templates VALUES ('4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'NAT BANK STAFF MARCH LUNCH 500', NULL, 'fixed_amount', 500.00, NULL, '2026-03-10', '2026-04-09', 'single', NULL, NULL, 0.00, false, NULL, NULL, NULL, '#FFFFFF', '#000000', true, '{}', '2026-03-10 04:17:11.385754+03', '2026-03-10 04:17:11.385754+03', NULL, NULL);


--
-- TOC entry 5463 (class 0 OID 33141)
-- Dependencies: 227
-- Data for Name: vouchers; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.vouchers VALUES ('88888888-8888-8888-8888-888888888881', '77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'TEST-944704', NULL, 100.00, 100.00, 'active', 'Test Beneficiary', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-20', 0, '{}', '2026-02-18 02:53:15.057811+03', '2026-02-18 02:53:15.057811+03', '33333333-3333-3333-3333-333333333333', NULL);
INSERT INTO public.vouchers VALUES ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'V002', NULL, 750.00, 750.00, 'active', 'Sarah Odhiambo', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-20', 0, '{}', '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', NULL);
INSERT INTO public.vouchers VALUES ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'V001', NULL, 500.00, 0.00, 'redeemed', 'John Kamau', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-20', 1, '{}', '2026-02-18 03:17:16.661252+03', '2026-02-18 03:17:16.661252+03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', NULL);
INSERT INTO public.vouchers VALUES ('893573a9-d98f-493a-aac0-b373ae3ac0d1', '77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'RFA-1773107552375-A0RV2ED', NULL, 100.00, 100.00, 'active', 'Brian Ndiwa', 'brianndiwa@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-31', 0, '{}', '2026-03-10 04:52:32.417164+03', '2026-03-10 04:52:32.417164+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.vouchers VALUES ('6f63b97a-3d53-40c8-85ed-be744cd5a242', 'f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'TRA-20260218-0001-AC09', NULL, 300.00, 300.00, 'active', 'Staff 1', 'staff1@example.com', '07012345678', NULL, 'employee', NULL, NULL, NULL, NULL, '2026-12-31', 0, '{}', '2026-02-19 00:55:20.702051+03', '2026-02-19 00:55:20.702051+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.vouchers VALUES ('573b38b1-f19b-4774-a221-f8f85f8e0e6a', 'f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'TRA-20260218-0002-FC90', NULL, 300.00, 300.00, 'active', 'Staff 2', 'staff2@example.com', '07012345679', NULL, 'employee', NULL, NULL, NULL, NULL, '2026-12-31', 0, '{}', '2026-02-19 00:55:20.738363+03', '2026-02-19 00:55:20.738363+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.vouchers VALUES ('941d93b0-b88b-4d52-b20f-f0620bfc5c3a', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-20260218-0001-58A4', NULL, 500.00, 500.00, 'active', 'Staff 1', 'staff1@rfa.com', '07012345678', NULL, 'employee', NULL, '57499418-70ef-41ff-b01e-a4e9c7364037', NULL, NULL, '2024-12-31', 0, '{}', '2026-02-19 01:32:25.99206+03', '2026-02-19 01:32:25.99206+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.vouchers VALUES ('36e47a8f-57cd-4e5c-b65b-6c9fa05272f3', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-20260218-0002-25DC', NULL, 500.00, 500.00, 'active', 'Staff 2', 'staff2@rfa.com', '07012345679', NULL, 'employee', NULL, '57499418-70ef-41ff-b01e-a4e9c7364037', NULL, NULL, '2024-12-31', 0, '{}', '2026-02-19 01:32:26.014445+03', '2026-02-19 01:32:26.014445+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.vouchers VALUES ('a3210cbf-9e9e-499e-b7b1-7baf9f1828a6', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-20260219-0001-A02D', NULL, 500.00, 500.00, 'active', 'John Doe', 'john@company.com', '1234567890', NULL, NULL, NULL, '6539da47-c266-4a37-910e-eec6a8b46696', NULL, NULL, '2024-12-31', 0, '{}', '2026-02-19 03:05:52.806937+03', '2026-02-19 03:05:52.806937+03', NULL, NULL);
INSERT INTO public.vouchers VALUES ('d63a66e6-cf81-41db-984c-c2bf064959a5', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-20260219-0002-71AD', NULL, 500.00, 500.00, 'active', 'Jane Smith', 'jane@company.com', NULL, NULL, NULL, NULL, '6539da47-c266-4a37-910e-eec6a8b46696', NULL, NULL, '2024-12-31', 0, '{}', '2026-02-19 03:05:52.826007+03', '2026-02-19 03:05:52.826007+03', NULL, NULL);
INSERT INTO public.vouchers VALUES ('4ab98fc7-4595-4b65-a65c-62a10467b909', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-20260219-0001-8783', NULL, 500.00, 500.00, 'active', 'John Doe', 'john@company.com', '1234567890', NULL, NULL, NULL, '7f443cc1-68bc-4b24-b417-807a8efc6b81', NULL, NULL, '2024-12-31', 0, '{}', '2026-02-19 03:13:10.18268+03', '2026-02-19 03:13:10.18268+03', NULL, NULL);
INSERT INTO public.vouchers VALUES ('7db134f5-836b-4b96-8cff-96f1938aea88', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-20260219-0002-8250', NULL, 500.00, 500.00, 'active', 'Jane Smith', 'jane@company.com', NULL, NULL, NULL, NULL, '7f443cc1-68bc-4b24-b417-807a8efc6b81', NULL, NULL, '2024-12-31', 0, '{}', '2026-02-19 03:13:10.19926+03', '2026-02-19 03:13:10.19926+03', NULL, NULL);
INSERT INTO public.vouchers VALUES ('c8a57a80-4079-4786-a930-bccaa6a8b88f', 'eba70e22-b0e7-43f5-aa68-21369c7e263b', '11111111-1111-1111-1111-111111111111', 'RFA-20260218-41AF69B13A57AE45', NULL, 100.00, 0.00, 'redeemed', 'Elias', 'john@alias.com', '+254700000000', NULL, 'employee', NULL, NULL, NULL, NULL, '2024-12-31', 2, '{}', '2026-02-18 03:24:16.191506+03', '2026-03-09 22:22:51.961929+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.vouchers VALUES ('c1839a86-4484-4332-b602-025b7d98706e', '77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'RFA-1773088058961-HXR3KJR', NULL, 100.00, 100.00, 'active', 'Brian K', 'bdiwa@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-19', 0, '{}', '2026-03-09 23:27:39.022213+03', '2026-03-09 23:27:39.022213+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.vouchers VALUES ('6f1c0542-0424-454d-9588-5cf20ee08983', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'RFA-1773089132439-YR77DOM', NULL, 500.00, 500.00, 'active', 'Brian K', 'bdiwa@gmail.com', '0704611605', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-31', 0, '{}', '2026-03-09 23:45:32.497768+03', '2026-03-09 23:45:32.497768+03', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', NULL);
INSERT INTO public.vouchers VALUES ('53a7923c-4c5c-461f-9aad-5d075301fe33', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773095144554-P5WAZLK', NULL, 500.00, 500.00, 'active', 'Brian K', 'bdiwa@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-12-30', 0, '{}', '2026-03-10 01:25:44.617734+03', '2026-03-10 01:25:44.617734+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('71247851-34cb-412e-a424-56ac38bcba88', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773095523305-0M4MSYE', NULL, 500.00, 500.00, 'active', 'keenlenx ndiwa', 'keeenlenx@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-12-30', 0, '{}', '2026-03-10 01:32:03.658199+03', '2026-03-10 01:32:03.658199+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('9ef2a1b8-5bbb-4040-86f3-a10093edd313', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773095814478-ZHDETW3', NULL, 500.00, 500.00, 'active', 'Brian K', 'bdiwa@gmail.com', '0704611605', NULL, NULL, NULL, NULL, NULL, NULL, '2026-04-08', 0, '{}', '2026-03-10 01:36:54.530503+03', '2026-03-10 01:36:54.530503+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('01dea55f-a9df-4a23-97ba-41e6f9c0b18e', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773096609537-4ZKW16O', NULL, 500.00, 500.00, 'active', 'Brian K', 'bdiwa@gmail.com', '0732742022', NULL, NULL, NULL, NULL, NULL, NULL, '2026-04-08', 0, '{}', '2026-03-10 01:50:09.599338+03', '2026-03-10 01:50:09.599338+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('7af4a2ba-6f98-4212-bfa1-7e0b627c7628', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773097564698-EL31KOT', NULL, 500.00, 500.00, 'active', 'Brian K', 'bdiwa@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-31', 0, '{}', '2026-03-10 02:06:04.749406+03', '2026-03-10 02:06:04.749406+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('c1f03052-8f81-4b52-ac0f-4351a278336b', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773101336566-E0QTYN3', NULL, 500.00, 500.00, 'active', 'John Kamau', 'admin@safaricom.co.ke', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-31', 0, '{}', '2026-03-10 03:08:56.63515+03', '2026-03-10 03:08:56.63515+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('29144777-532b-44ff-9a48-3f99377bce4a', 'aa32a1e2-e44d-4cad-977d-e5c9865ad13a', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773105304288-XTAH02A', NULL, 500.00, 500.00, 'active', 'Brian K', 'bdiwa@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-11', 0, '{}', '2026-03-10 04:15:04.537289+03', '2026-03-10 04:15:04.537289+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('4be72dab-1ecd-44fa-b891-aed023950b15', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773105502293-CCGZ6UE', NULL, 500.00, 500.00, 'active', 'John Doe', 'john@example.com', '0712345678', NULL, NULL, NULL, NULL, NULL, NULL, '2025-12-31', 0, '{}', '2026-03-10 04:18:22.336198+03', '2026-03-10 04:18:22.336198+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('5bc51a23-4a96-4d38-9046-cd43bf073fa6', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773105502354-Y9XGXOR', NULL, 500.00, 500.00, 'active', 'Jane Smith', 'jane@example.com', '0798765432', NULL, NULL, NULL, NULL, NULL, NULL, '2026-04-09', 0, '{}', '2026-03-10 04:18:22.355395+03', '2026-03-10 04:18:22.355395+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('70960fdb-5d6d-4bd2-b5b5-821ac10b2184', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773105502360-I053FO8', NULL, 500.00, 500.00, 'active', 'Bob Johnson', 'bob@example.com', '', NULL, NULL, NULL, NULL, NULL, NULL, '2025-06-30', 0, '{}', '2026-03-10 04:18:22.361121+03', '2026-03-10 04:18:22.361121+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('8548a82b-ec74-4ec3-9968-d901c7b28df8', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773105757588-76PACEO', NULL, 500.00, 500.00, 'active', 'John Kamau', 'admin@safaricom.co.ke', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-01', 0, '{}', '2026-03-10 04:22:37.635944+03', '2026-03-10 04:22:37.635944+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('d56127ff-db10-4fdc-b462-94955ca487d9', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773105887966-NPYDTMT', NULL, 500.00, 500.00, 'active', 'Jane Smith', 'jane@example.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-04', 0, '{}', '2026-03-10 04:24:48.045098+03', '2026-03-10 04:24:48.045098+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('4a39026a-0991-4c2d-8cf3-c36f8b83ea19', 'aa32a1e2-e44d-4cad-977d-e5c9865ad13a', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773105957712-4IQ0LPD', NULL, 500.00, 500.00, 'active', 'John Doe', 'john@example.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-11', 0, '{}', '2026-03-10 04:25:57.801332+03', '2026-03-10 04:25:57.801332+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('c217247d-181c-48ff-a84e-3205f64f63ad', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773105986670-EDIGULI', NULL, 500.00, 500.00, 'active', 'John Kamau', 'admin@safaricom.co.ke', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-30', 0, '{}', '2026-03-10 04:26:26.749622+03', '2026-03-10 04:26:26.749622+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);
INSERT INTO public.vouchers VALUES ('fd929897-3b4e-4baa-b109-f37a31c12071', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-1773106076763-ANS9LM8', NULL, 500.00, 500.00, 'active', 'keenlenx ndiwa', 'keeenlenx@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-11', 0, '{}', '2026-03-10 04:27:56.81578+03', '2026-03-10 04:27:56.81578+03', '1ee87751-8c00-4bde-a199-3756fa5682b3', NULL);


--
-- TOC entry 5241 (class 2606 OID 33566)
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5209 (class 2606 OID 33359)
-- Name: billing_plans billing_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_plans
    ADD CONSTRAINT billing_plans_pkey PRIMARY KEY (id);


--
-- TOC entry 5211 (class 2606 OID 33361)
-- Name: billing_plans billing_plans_plan_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_plans
    ADD CONSTRAINT billing_plans_plan_code_key UNIQUE (plan_code);


--
-- TOC entry 5214 (class 2606 OID 33393)
-- Name: client_subscriptions client_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_subscriptions
    ADD CONSTRAINT client_subscriptions_pkey PRIMARY KEY (id);


--
-- TOC entry 5205 (class 2606 OID 33320)
-- Name: gift_deliveries gift_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_deliveries
    ADD CONSTRAINT gift_deliveries_pkey PRIMARY KEY (id);


--
-- TOC entry 5221 (class 2606 OID 33448)
-- Name: invoices invoices_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_invoice_number_key UNIQUE (invoice_number);


--
-- TOC entry 5223 (class 2606 OID 33446)
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- TOC entry 5159 (class 2606 OID 33011)
-- Name: merchants merchants_merchant_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_merchant_code_key UNIQUE (merchant_code);


--
-- TOC entry 5161 (class 2606 OID 33009)
-- Name: merchants merchants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_pkey PRIMARY KEY (id);


--
-- TOC entry 5201 (class 2606 OID 33283)
-- Name: purchase_orders purchase_orders_order_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_order_number_key UNIQUE (order_number);


--
-- TOC entry 5203 (class 2606 OID 33281)
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 5196 (class 2606 OID 33224)
-- Name: redemptions redemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_pkey PRIMARY KEY (id);


--
-- TOC entry 5228 (class 2606 OID 33492)
-- Name: settlements settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_pkey PRIMARY KEY (id);


--
-- TOC entry 5230 (class 2606 OID 33494)
-- Name: settlements settlements_settlement_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_settlement_number_key UNIQUE (settlement_number);


--
-- TOC entry 5143 (class 2606 OID 32939)
-- Name: tenants tenants_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_email_key UNIQUE (email);


--
-- TOC entry 5145 (class 2606 OID 32937)
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- TOC entry 5237 (class 2606 OID 33533)
-- Name: transaction_log transaction_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_log
    ADD CONSTRAINT transaction_log_pkey PRIMARY KEY (id);


--
-- TOC entry 5239 (class 2606 OID 33535)
-- Name: transaction_log transaction_log_transaction_reference_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_log
    ADD CONSTRAINT transaction_log_transaction_reference_key UNIQUE (transaction_reference);


--
-- TOC entry 5152 (class 2606 OID 32962)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 5154 (class 2606 OID 32960)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5175 (class 2606 OID 33123)
-- Name: voucher_batches voucher_batches_batch_reference_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_batches
    ADD CONSTRAINT voucher_batches_batch_reference_key UNIQUE (batch_reference);


--
-- TOC entry 5177 (class 2606 OID 33121)
-- Name: voucher_batches voucher_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_batches
    ADD CONSTRAINT voucher_batches_pkey PRIMARY KEY (id);


--
-- TOC entry 5169 (class 2606 OID 33084)
-- Name: voucher_merchant_restrictions voucher_merchant_restrictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_merchant_restrictions
    ADD CONSTRAINT voucher_merchant_restrictions_pkey PRIMARY KEY (id);


--
-- TOC entry 5171 (class 2606 OID 33086)
-- Name: voucher_merchant_restrictions voucher_merchant_restrictions_voucher_template_id_merchant__key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_merchant_restrictions
    ADD CONSTRAINT voucher_merchant_restrictions_voucher_template_id_merchant__key UNIQUE (voucher_template_id, merchant_id);


--
-- TOC entry 5166 (class 2606 OID 33056)
-- Name: voucher_templates voucher_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_templates
    ADD CONSTRAINT voucher_templates_pkey PRIMARY KEY (id);


--
-- TOC entry 5188 (class 2606 OID 33167)
-- Name: vouchers vouchers_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_code_key UNIQUE (code);


--
-- TOC entry 5190 (class 2606 OID 33165)
-- Name: vouchers vouchers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_pkey PRIMARY KEY (id);


--
-- TOC entry 5242 (class 1259 OID 33580)
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- TOC entry 5243 (class 1259 OID 33577)
-- Name: idx_audit_logs_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_lookup ON public.audit_logs USING btree (entity_type, entity_id, created_at);


--
-- TOC entry 5244 (class 1259 OID 33579)
-- Name: idx_audit_logs_tenant_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_tenant_time ON public.audit_logs USING btree (tenant_id, created_at);


--
-- TOC entry 5245 (class 1259 OID 33578)
-- Name: idx_audit_logs_user_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_user_time ON public.audit_logs USING btree (user_id, created_at);


--
-- TOC entry 5212 (class 1259 OID 33372)
-- Name: idx_billing_plans_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_billing_plans_active ON public.billing_plans USING btree (is_active);


--
-- TOC entry 5215 (class 1259 OID 33415)
-- Name: idx_client_subscriptions_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_client_subscriptions_active ON public.client_subscriptions USING btree (tenant_id) WHERE (is_active = true);


--
-- TOC entry 5216 (class 1259 OID 33414)
-- Name: idx_client_subscriptions_tenant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_client_subscriptions_tenant ON public.client_subscriptions USING btree (tenant_id);


--
-- TOC entry 5206 (class 1259 OID 33331)
-- Name: idx_gift_deliveries_purchase; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gift_deliveries_purchase ON public.gift_deliveries USING btree (purchase_order_id);


--
-- TOC entry 5207 (class 1259 OID 33332)
-- Name: idx_gift_deliveries_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gift_deliveries_status ON public.gift_deliveries USING btree (delivery_status);


--
-- TOC entry 5217 (class 1259 OID 33466)
-- Name: idx_invoices_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoices_created_at ON public.invoices USING btree (created_at);


--
-- TOC entry 5218 (class 1259 OID 33465)
-- Name: idx_invoices_due_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoices_due_date ON public.invoices USING btree (due_date) WHERE (status = ANY (ARRAY['issued'::public.invoice_status_enum, 'overdue'::public.invoice_status_enum]));


--
-- TOC entry 5219 (class 1259 OID 33464)
-- Name: idx_invoices_tenant_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoices_tenant_status ON public.invoices USING btree (tenant_id, status);


--
-- TOC entry 5155 (class 1259 OID 33028)
-- Name: idx_merchants_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_merchants_category ON public.merchants USING btree (merchant_category);


--
-- TOC entry 5156 (class 1259 OID 33029)
-- Name: idx_merchants_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_merchants_location ON public.merchants USING btree (latitude, longitude) WHERE (latitude IS NOT NULL);


--
-- TOC entry 5157 (class 1259 OID 33027)
-- Name: idx_merchants_tenant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_merchants_tenant ON public.merchants USING btree (tenant_id);


--
-- TOC entry 5197 (class 1259 OID 33299)
-- Name: idx_purchase_orders_consumer_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_purchase_orders_consumer_email ON public.purchase_orders USING btree (consumer_email);


--
-- TOC entry 5198 (class 1259 OID 33300)
-- Name: idx_purchase_orders_payment_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_purchase_orders_payment_status ON public.purchase_orders USING btree (payment_status);


--
-- TOC entry 5199 (class 1259 OID 33301)
-- Name: idx_purchase_orders_scheduled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_purchase_orders_scheduled ON public.purchase_orders USING btree (scheduled_delivery_date) WHERE ((scheduled_delivery_date IS NOT NULL) AND (delivered_at IS NULL));


--
-- TOC entry 5191 (class 1259 OID 33252)
-- Name: idx_redemptions_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_redemptions_created_at ON public.redemptions USING btree (created_at);


--
-- TOC entry 5192 (class 1259 OID 33251)
-- Name: idx_redemptions_merchant_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_redemptions_merchant_date ON public.redemptions USING btree (merchant_id, created_at);


--
-- TOC entry 5193 (class 1259 OID 33250)
-- Name: idx_redemptions_voucher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_redemptions_voucher ON public.redemptions USING btree (voucher_id);


--
-- TOC entry 5194 (class 1259 OID 33597)
-- Name: idx_redemptions_voucher_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_redemptions_voucher_created ON public.redemptions USING btree (voucher_id, created_at);


--
-- TOC entry 5224 (class 1259 OID 33510)
-- Name: idx_settlements_merchant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_settlements_merchant ON public.settlements USING btree (merchant_id);


--
-- TOC entry 5225 (class 1259 OID 33512)
-- Name: idx_settlements_period; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_settlements_period ON public.settlements USING btree (period_start, period_end);


--
-- TOC entry 5226 (class 1259 OID 33511)
-- Name: idx_settlements_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_settlements_status ON public.settlements USING btree (status);


--
-- TOC entry 5231 (class 1259 OID 33598)
-- Name: idx_transaction_log_created_source; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaction_log_created_source ON public.transaction_log USING btree (created_at, source_type);


--
-- TOC entry 5232 (class 1259 OID 33552)
-- Name: idx_transaction_log_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaction_log_dates ON public.transaction_log USING btree (created_at);


--
-- TOC entry 5233 (class 1259 OID 33551)
-- Name: idx_transaction_log_source; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaction_log_source ON public.transaction_log USING btree (source_type, source_id);


--
-- TOC entry 5234 (class 1259 OID 33553)
-- Name: idx_transaction_log_tenants; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaction_log_tenants ON public.transaction_log USING btree (from_tenant_id, to_tenant_id);


--
-- TOC entry 5235 (class 1259 OID 33554)
-- Name: idx_transaction_log_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transaction_log_type ON public.transaction_log USING btree (transaction_type);


--
-- TOC entry 5146 (class 1259 OID 32988)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 5147 (class 1259 OID 32990)
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone) WHERE (phone IS NOT NULL);


--
-- TOC entry 5148 (class 1259 OID 33964)
-- Name: idx_users_reset_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_reset_token ON public.users USING btree (password_reset_token);


--
-- TOC entry 5149 (class 1259 OID 32991)
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- TOC entry 5150 (class 1259 OID 32989)
-- Name: idx_users_tenant_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_tenant_role ON public.users USING btree (tenant_id, role);


--
-- TOC entry 5172 (class 1259 OID 33140)
-- Name: idx_voucher_batches_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_voucher_batches_status ON public.voucher_batches USING btree (status);


--
-- TOC entry 5173 (class 1259 OID 33139)
-- Name: idx_voucher_batches_tenant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_voucher_batches_tenant ON public.voucher_batches USING btree (tenant_id);


--
-- TOC entry 5167 (class 1259 OID 33102)
-- Name: idx_voucher_merchant_restrictions_template; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_voucher_merchant_restrictions_template ON public.voucher_merchant_restrictions USING btree (voucher_template_id);


--
-- TOC entry 5162 (class 1259 OID 33073)
-- Name: idx_voucher_templates_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_voucher_templates_dates ON public.voucher_templates USING btree (valid_from, valid_to);


--
-- TOC entry 5163 (class 1259 OID 33074)
-- Name: idx_voucher_templates_public; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_voucher_templates_public ON public.voucher_templates USING btree (is_public_visible) WHERE (is_public_visible = true);


--
-- TOC entry 5164 (class 1259 OID 33072)
-- Name: idx_voucher_templates_tenant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_voucher_templates_tenant ON public.voucher_templates USING btree (tenant_id);


--
-- TOC entry 5178 (class 1259 OID 33963)
-- Name: idx_vouchers_batch_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_batch_id ON public.vouchers USING btree (batch_id);


--
-- TOC entry 5179 (class 1259 OID 33200)
-- Name: idx_vouchers_beneficiary_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_beneficiary_email ON public.vouchers USING btree (beneficiary_email) WHERE (beneficiary_email IS NOT NULL);


--
-- TOC entry 5180 (class 1259 OID 33199)
-- Name: idx_vouchers_beneficiary_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_beneficiary_phone ON public.vouchers USING btree (beneficiary_phone) WHERE (beneficiary_phone IS NOT NULL);


--
-- TOC entry 5181 (class 1259 OID 33201)
-- Name: idx_vouchers_beneficiary_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_beneficiary_user ON public.vouchers USING btree (beneficiary_user_id) WHERE (beneficiary_user_id IS NOT NULL);


--
-- TOC entry 5182 (class 1259 OID 33198)
-- Name: idx_vouchers_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_code ON public.vouchers USING btree (code);


--
-- TOC entry 5183 (class 1259 OID 33203)
-- Name: idx_vouchers_expiry; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_expiry ON public.vouchers USING btree (expires_at) WHERE (status = 'active'::public.voucher_status_enum);


--
-- TOC entry 5184 (class 1259 OID 33202)
-- Name: idx_vouchers_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_status ON public.vouchers USING btree (status);


--
-- TOC entry 5185 (class 1259 OID 33596)
-- Name: idx_vouchers_tenant_expiry; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_tenant_expiry ON public.vouchers USING btree (tenant_id, expires_at) WHERE (status = 'active'::public.voucher_status_enum);


--
-- TOC entry 5186 (class 1259 OID 33204)
-- Name: idx_vouchers_tenant_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vouchers_tenant_status ON public.vouchers USING btree (tenant_id, status);


--
-- TOC entry 5302 (class 2620 OID 33593)
-- Name: vouchers generate_voucher_code_before_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER generate_voucher_code_before_insert BEFORE INSERT ON public.vouchers FOR EACH ROW WHEN ((new.code IS NULL)) EXECUTE FUNCTION public.generate_voucher_code();


--
-- TOC entry 5306 (class 2620 OID 33588)
-- Name: billing_plans update_billing_plans_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_billing_plans_updated_at BEFORE UPDATE ON public.billing_plans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5307 (class 2620 OID 33589)
-- Name: client_subscriptions update_client_subscriptions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_client_subscriptions_updated_at BEFORE UPDATE ON public.client_subscriptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5308 (class 2620 OID 33590)
-- Name: invoices update_invoices_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5300 (class 2620 OID 33584)
-- Name: merchants update_merchants_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_merchants_updated_at BEFORE UPDATE ON public.merchants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5305 (class 2620 OID 33587)
-- Name: purchase_orders update_purchase_orders_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_purchase_orders_updated_at BEFORE UPDATE ON public.purchase_orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5309 (class 2620 OID 33591)
-- Name: settlements update_settlements_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_settlements_updated_at BEFORE UPDATE ON public.settlements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5298 (class 2620 OID 33582)
-- Name: tenants update_tenants_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON public.tenants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5299 (class 2620 OID 33583)
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5304 (class 2620 OID 33595)
-- Name: redemptions update_voucher_after_redemption; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_voucher_after_redemption AFTER INSERT ON public.redemptions FOR EACH ROW EXECUTE FUNCTION public.update_voucher_on_redemption();


--
-- TOC entry 5301 (class 2620 OID 33585)
-- Name: voucher_templates update_voucher_templates_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_voucher_templates_updated_at BEFORE UPDATE ON public.voucher_templates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5303 (class 2620 OID 33586)
-- Name: vouchers update_vouchers_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_vouchers_updated_at BEFORE UPDATE ON public.vouchers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5296 (class 2606 OID 33567)
-- Name: audit_logs audit_logs_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- TOC entry 5297 (class 2606 OID 33572)
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 5281 (class 2606 OID 33362)
-- Name: billing_plans billing_plans_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_plans
    ADD CONSTRAINT billing_plans_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5282 (class 2606 OID 33367)
-- Name: billing_plans billing_plans_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.billing_plans
    ADD CONSTRAINT billing_plans_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5283 (class 2606 OID 33399)
-- Name: client_subscriptions client_subscriptions_billing_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_subscriptions
    ADD CONSTRAINT client_subscriptions_billing_plan_id_fkey FOREIGN KEY (billing_plan_id) REFERENCES public.billing_plans(id);


--
-- TOC entry 5284 (class 2606 OID 33404)
-- Name: client_subscriptions client_subscriptions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_subscriptions
    ADD CONSTRAINT client_subscriptions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5285 (class 2606 OID 33394)
-- Name: client_subscriptions client_subscriptions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_subscriptions
    ADD CONSTRAINT client_subscriptions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- TOC entry 5286 (class 2606 OID 33409)
-- Name: client_subscriptions client_subscriptions_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_subscriptions
    ADD CONSTRAINT client_subscriptions_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5246 (class 2606 OID 32978)
-- Name: tenants fk_tenants_created_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT fk_tenants_created_by FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5247 (class 2606 OID 33373)
-- Name: tenants fk_tenants_subscription_plan; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT fk_tenants_subscription_plan FOREIGN KEY (subscription_plan_id) REFERENCES public.billing_plans(id);


--
-- TOC entry 5512 (class 0 OID 0)
-- Dependencies: 5247
-- Name: CONSTRAINT fk_tenants_subscription_plan ON tenants; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT fk_tenants_subscription_plan ON public.tenants IS 'Links tenant to their current billing plan';


--
-- TOC entry 5248 (class 2606 OID 32983)
-- Name: tenants fk_tenants_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT fk_tenants_updated_by FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5279 (class 2606 OID 33321)
-- Name: gift_deliveries gift_deliveries_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_deliveries
    ADD CONSTRAINT gift_deliveries_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_orders(id) ON DELETE CASCADE;


--
-- TOC entry 5280 (class 2606 OID 33326)
-- Name: gift_deliveries gift_deliveries_voucher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_deliveries
    ADD CONSTRAINT gift_deliveries_voucher_id_fkey FOREIGN KEY (voucher_id) REFERENCES public.vouchers(id) ON DELETE CASCADE;


--
-- TOC entry 5287 (class 2606 OID 33454)
-- Name: invoices invoices_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5288 (class 2606 OID 33449)
-- Name: invoices invoices_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- TOC entry 5289 (class 2606 OID 33459)
-- Name: invoices invoices_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5253 (class 2606 OID 33017)
-- Name: merchants merchants_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5254 (class 2606 OID 33012)
-- Name: merchants merchants_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- TOC entry 5255 (class 2606 OID 33022)
-- Name: merchants merchants_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5276 (class 2606 OID 33284)
-- Name: purchase_orders purchase_orders_consumer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_consumer_id_fkey FOREIGN KEY (consumer_id) REFERENCES public.users(id);


--
-- TOC entry 5277 (class 2606 OID 33294)
-- Name: purchase_orders purchase_orders_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5278 (class 2606 OID 33289)
-- Name: purchase_orders purchase_orders_voucher_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_voucher_template_id_fkey FOREIGN KEY (voucher_template_id) REFERENCES public.voucher_templates(id);


--
-- TOC entry 5271 (class 2606 OID 33245)
-- Name: redemptions redemptions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5272 (class 2606 OID 33230)
-- Name: redemptions redemptions_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(id) ON DELETE CASCADE;


--
-- TOC entry 5273 (class 2606 OID 33235)
-- Name: redemptions redemptions_redeemed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_redeemed_by_fkey FOREIGN KEY (redeemed_by) REFERENCES public.users(id);


--
-- TOC entry 5274 (class 2606 OID 33240)
-- Name: redemptions redemptions_reversed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_reversed_by_fkey FOREIGN KEY (reversed_by) REFERENCES public.users(id);


--
-- TOC entry 5275 (class 2606 OID 33225)
-- Name: redemptions redemptions_voucher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_voucher_id_fkey FOREIGN KEY (voucher_id) REFERENCES public.vouchers(id) ON DELETE CASCADE;


--
-- TOC entry 5290 (class 2606 OID 33500)
-- Name: settlements settlements_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5291 (class 2606 OID 33495)
-- Name: settlements settlements_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(id) ON DELETE CASCADE;


--
-- TOC entry 5292 (class 2606 OID 33505)
-- Name: settlements settlements_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5293 (class 2606 OID 33546)
-- Name: transaction_log transaction_log_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_log
    ADD CONSTRAINT transaction_log_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5294 (class 2606 OID 33536)
-- Name: transaction_log transaction_log_from_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_log
    ADD CONSTRAINT transaction_log_from_tenant_id_fkey FOREIGN KEY (from_tenant_id) REFERENCES public.tenants(id);


--
-- TOC entry 5295 (class 2606 OID 33541)
-- Name: transaction_log transaction_log_to_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_log
    ADD CONSTRAINT transaction_log_to_tenant_id_fkey FOREIGN KEY (to_tenant_id) REFERENCES public.tenants(id);


--
-- TOC entry 5249 (class 2606 OID 32968)
-- Name: users users_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5250 (class 2606 OID 33965)
-- Name: users users_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(id);


--
-- TOC entry 5251 (class 2606 OID 32963)
-- Name: users users_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- TOC entry 5252 (class 2606 OID 32973)
-- Name: users users_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5262 (class 2606 OID 33134)
-- Name: voucher_batches voucher_batches_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_batches
    ADD CONSTRAINT voucher_batches_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5263 (class 2606 OID 33124)
-- Name: voucher_batches voucher_batches_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_batches
    ADD CONSTRAINT voucher_batches_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- TOC entry 5264 (class 2606 OID 33129)
-- Name: voucher_batches voucher_batches_voucher_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_batches
    ADD CONSTRAINT voucher_batches_voucher_template_id_fkey FOREIGN KEY (voucher_template_id) REFERENCES public.voucher_templates(id);


--
-- TOC entry 5259 (class 2606 OID 33097)
-- Name: voucher_merchant_restrictions voucher_merchant_restrictions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_merchant_restrictions
    ADD CONSTRAINT voucher_merchant_restrictions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5260 (class 2606 OID 33092)
-- Name: voucher_merchant_restrictions voucher_merchant_restrictions_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_merchant_restrictions
    ADD CONSTRAINT voucher_merchant_restrictions_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(id) ON DELETE CASCADE;


--
-- TOC entry 5261 (class 2606 OID 33087)
-- Name: voucher_merchant_restrictions voucher_merchant_restrictions_voucher_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_merchant_restrictions
    ADD CONSTRAINT voucher_merchant_restrictions_voucher_template_id_fkey FOREIGN KEY (voucher_template_id) REFERENCES public.voucher_templates(id) ON DELETE CASCADE;


--
-- TOC entry 5256 (class 2606 OID 33062)
-- Name: voucher_templates voucher_templates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_templates
    ADD CONSTRAINT voucher_templates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5257 (class 2606 OID 33057)
-- Name: voucher_templates voucher_templates_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_templates
    ADD CONSTRAINT voucher_templates_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- TOC entry 5258 (class 2606 OID 33067)
-- Name: voucher_templates voucher_templates_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.voucher_templates
    ADD CONSTRAINT voucher_templates_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5265 (class 2606 OID 33183)
-- Name: vouchers vouchers_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.voucher_batches(id);


--
-- TOC entry 5266 (class 2606 OID 33178)
-- Name: vouchers vouchers_beneficiary_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_beneficiary_user_id_fkey FOREIGN KEY (beneficiary_user_id) REFERENCES public.users(id);


--
-- TOC entry 5267 (class 2606 OID 33188)
-- Name: vouchers vouchers_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5268 (class 2606 OID 33173)
-- Name: vouchers vouchers_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- TOC entry 5269 (class 2606 OID 33193)
-- Name: vouchers vouchers_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5270 (class 2606 OID 33168)
-- Name: vouchers vouchers_voucher_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_voucher_template_id_fkey FOREIGN KEY (voucher_template_id) REFERENCES public.voucher_templates(id);


-- Completed on 2026-03-10 13:40:27

--
-- PostgreSQL database dump complete
--

\unrestrict x9cCatN1TrOC1d8RdUuHuB1YBnRrhqdQL99qKph4DwX3T51M6D0OWUnbzYu03In

