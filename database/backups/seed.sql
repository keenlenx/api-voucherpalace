-- ============================================================================
-- Romeo Fox Alpha Voucher Management Platform - Seed Data
-- PostgreSQL 15+ Compatible
-- ============================================================================

-- Connect to the database
\connect voucherpalace

-- ============================================================================
-- DISABLE TRIGGERS TEMPORARILY (optional - uncomment if needed)
-- ============================================================================
-- SET session_replication_role = 'replica';

-- ============================================================================
-- 1. Insert Tenants (no dependencies)
-- ============================================================================
INSERT INTO tenants (id, tenant_name, tenant_type, email, phone, status) VALUES
('11111111-1111-1111-1111-111111111111', 'Romeo Fox Alpha Limited', 'rfa_internal', 'system@romeofoxalpha.com', NULL, 'active'),
('22222222-2222-2222-2222-222222222222', 'Kenya Airways', 'corporate', 'hr@kenya-airways.com', NULL, 'active'),
('b1e04148-1c41-415f-992c-8aacddb4498a', 'National Bank', 'corporate', 'info@nbk.com', '0702000222', 'active'),
('3e0d8385-9c7a-4462-a009-63fdd514da8e', 'Kool Cutz', 'corporate', 'info@koolcutz.com', '0724727181', 'active'),
('6cba5fa0-2099-4c33-9157-8773ebf756de', 'Hot Foods', 'merchant', 'info@hotfoods.com', '0768908987', 'active')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. Insert Billing Plans (no dependencies)
-- ============================================================================
INSERT INTO billing_plans (id, plan_name, plan_code, plan_type, description, monthly_fixed_fee, per_voucher_fee, transaction_percentage, features) VALUES
('22222222-2222-2222-2222-222222222221', 'Starter', 'STARTER', 'pay_as_you_go', 'Pay only for what you use', 0, 0.50, 2.00, '{"reports": "basic", "max_users": 5}'::JSONB),
('22222222-2222-2222-2222-222222222222', 'Professional', 'PRO', 'hybrid', 'For growing businesses', 49.00, 0.25, 1.50, '{"reports": "advanced", "max_users": 20, "api_access": true}'::JSONB),
('22222222-2222-2222-2222-222222222223', 'Enterprise', 'ENTERPRISE', 'subscription', 'Custom solutions for large organizations', 199.00, 0.10, 1.00, '{"reports": "custom", "max_users": -1, "api_access": true, "dedicated_support": true}'::JSONB)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 3. Insert Users (depends on tenants)
-- Note: Passwords are hashed - these are example hashes
-- ============================================================================
INSERT INTO users (id, tenant_id, email, password_hash, first_name, last_name, phone, role, is_email_verified, status) VALUES
-- Super Admin
('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'admin@romeofoxalpha.com', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'System', 'Administrator', NULL, 'super_admin', true, 'active'),

-- Client Admins
('98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', '11111111-1111-1111-1111-111111111111', 'brianndiwa@gmail.com', '$2b$10$O8Ss9F5T9ZEXnUdqf.SQy.02dnd/bqvsCdE8Pm6wCi52cUTLU7M8G', 'Brian', 'Ndiwa', '+254704611605', 'client_admin', true, 'active'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', 'admin@safaricom.co.ke', '$2a$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'John', 'Kamau', NULL, 'client_admin', true, 'active'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '22222222-2222-2222-2222-222222222222', 'admin@kenya-airways.com', '$2a$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'Sarah', 'Odhiambo', NULL, 'client_admin', true, 'active'),
('d18b1d25-1ceb-4a56-a5e6-16476c4fb514', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'jane@example.com', '$2b$10$l1Bu65l4snFFkTeb4U.BHOky3AWRB0c9WIOjEFk5aBSKKoVhTnNDi', 'Jane', 'Smith', '798765432', 'client_admin', true, 'active'),

-- Consumers
('1ee87751-8c00-4bde-a199-3756fa5682b3', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'bdiwa@gmail.com', '$2b$10$O8Ss9F5T9ZEXnUdqf.SQy.02dnd/bqvsCdE8Pm6wCi52cUTLU7M8G', 'Brian', 'K', '0704611605', 'consumer', true, 'active'),
('dabf03af-a6fa-46c5-aaea-01c7a99bbc13', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'keeenlenx@gmail.com', '$2b$10$YOXeYg1pnHBN2KF3rmvI7uxjLPkbzFHikxmqtcFSA7xa4gk9BqHOW', 'keenlenx', 'ndiwa', '0713820049', 'consumer', true, 'active'),
('186243ed-75de-4133-931d-f9091c67580e', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'john@example.com', '$2b$10$GuDmHeGKRvBGjOeZggHiC.lei7rQl.XiaK2grJodTZt2lcb0q5pui', 'John', 'Doe', '712345678', 'consumer', true, 'active')
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- 4. Insert Merchants (depends on tenants)
-- ============================================================================
INSERT INTO merchants (id, tenant_id, merchant_name, merchant_code, merchant_category, settlement_period, is_active) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '11111111-1111-1111-1111-111111111111', 'Test Restaurant', 'TEST001', 'Restaurant', 'weekly', true),
('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Java House', 'JAVA01', 'Restaurant', 'weekly', true),
('a0000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'KFC', 'KFC01', 'Fast Food', 'weekly', true)
ON CONFLICT (merchant_code) DO NOTHING;

-- ============================================================================
-- 5. Insert Voucher Templates (depends on tenants)
-- ============================================================================
INSERT INTO voucher_templates (id, tenant_id, template_name, description, voucher_type, value_amount, valid_from, valid_to, usage_limit_type, is_public_visible, public_price) VALUES
('77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'Test Voucher', 'Basic test voucher', 'fixed_amount', 100.00, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 'single', false, NULL),
('f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'Tradewinds Lunch Voucher', 'KSH 300 lunch voucher', 'fixed_amount', 300.00, '2026-02-01', '2026-12-31', 'multi', true, 300.00),
('f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'Staff Lunch Voucher', 'Daily lunch at partner restaurants', 'fixed_amount', 500.00, '2024-01-01', '2024-12-31', 'single', true, 500.00),
('4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'National Bank Lunch', '500 KES lunch voucher', 'fixed_amount', 500.00, '2026-01-01', '2026-12-31', 'multi', true, 500.00),
('4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'NAT BANK STAFF MARCH LUNCH', 'March 2026 staff lunch', 'fixed_amount', 500.00, '2026-03-10', '2026-04-09', 'single', false, NULL),
('eba70e22-b0e7-43f5-aa68-21369c7e263b', '11111111-1111-1111-1111-111111111111', 'Holiday Special', '20% off holiday discount', 'percentage', 100.00, '2024-12-01', '2024-12-31', 'single', true, 100.00)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 6. Insert Voucher Batches (depends on tenants, voucher_templates)
-- ============================================================================
INSERT INTO voucher_batches (id, tenant_id, batch_reference, voucher_template_id, total_count, successful_count, status, created_by) VALUES
('7f443cc1-68bc-4b24-b417-807a8efc6b81', '11111111-1111-1111-1111-111111111111', 'BATCH-20260310-001', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 2, 2, 'completed', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('b5080460-6d5e-4b6f-b1e9-8fbc8fd74eb5', '11111111-1111-1111-1111-111111111111', 'BATCH-20260310-002', 'f3b6eef4-312a-472e-b59a-90f47835608b', 2, 2, 'completed', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 7. Insert Vouchers (depends on tenants, voucher_templates, users, voucher_batches)
-- ============================================================================
INSERT INTO vouchers (id, voucher_template_id, tenant_id, code, original_value, remaining_value, status, beneficiary_name, beneficiary_email, beneficiary_phone, expires_at, batch_id, created_by) VALUES
-- Test vouchers
('88888888-8888-8888-8888-888888888881', '77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'TEST-944704', 100.00, 100.00, 'active', 'Test Beneficiary', NULL, NULL, CURRENT_DATE + INTERVAL '30 days', NULL, '33333333-3333-3333-3333-333333333333'),
('893573a9-d98f-493a-aac0-b373ae3ac0d1', '77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'RFA-20260310-001', 100.00, 100.00, 'active', 'Brian Ndiwa', 'brianndiwa@gmail.com', NULL, CURRENT_DATE + INTERVAL '30 days', NULL, '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),

-- Tradewinds vouchers
('6f63b97a-3d53-40c8-85ed-be744cd5a242', 'f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'TRA-20260310-001', 300.00, 300.00, 'active', 'Staff 1', 'staff1@example.com', '07012345678', '2026-12-31', 'b5080460-6d5e-4b6f-b1e9-8fbc8fd74eb5', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('573b38b1-f19b-4774-a221-f8f85f8e0e6a', 'f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'TRA-20260310-002', 300.00, 300.00, 'active', 'Staff 2', 'staff2@example.com', '07012345679', '2026-12-31', 'b5080460-6d5e-4b6f-b1e9-8fbc8fd74eb5', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),

-- Staff lunch vouchers
('4ab98fc7-4595-4b65-a65c-62a10467b909', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-20260310-001', 500.00, 500.00, 'active', 'John Doe', 'john@company.com', '1234567890', '2024-12-31', '7f443cc1-68bc-4b24-b417-807a8efc6b81', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('7db134f5-836b-4b96-8cff-96f1938aea88', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-20260310-002', 500.00, 500.00, 'active', 'Jane Smith', 'jane@company.com', NULL, '2024-12-31', '7f443cc1-68bc-4b24-b417-807a8efc6b81', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),

-- National Bank vouchers
('53a7923c-4c5c-461f-9aad-5d075301fe33', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-20260310-002', 500.00, 500.00, 'active', 'Brian K', 'bdiwa@gmail.com', NULL, '2026-12-30', NULL, '1ee87751-8c00-4bde-a199-3756fa5682b3'),
('71247851-34cb-412e-a424-56ac38bcba88', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-20260310-003', 500.00, 500.00, 'active', 'keenlenx ndiwa', 'keeenlenx@gmail.com', NULL, '2026-12-30', NULL, '1ee87751-8c00-4bde-a199-3756fa5682b3'),
('c217247d-181c-48ff-a84e-3205f64f63ad', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-20260310-004', 500.00, 500.00, 'active', 'John Kamau', 'admin@safaricom.co.ke', NULL, '2026-09-30', NULL, '1ee87751-8c00-4bde-a199-3756fa5682b3'),

-- March lunch vouchers
('4be72dab-1ecd-44fa-b891-aed023950b15', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-20260310-005', 500.00, 500.00, 'active', 'John Doe', 'john@example.com', '0712345678', '2025-12-31', NULL, '1ee87751-8c00-4bde-a199-3756fa5682b3'),
('5bc51a23-4a96-4d38-9046-cd43bf073fa6', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-20260310-006', 500.00, 500.00, 'active', 'Jane Smith', 'jane@example.com', '0798765432', '2026-04-09', NULL, '1ee87751-8c00-4bde-a199-3756fa5682b3'),
('fd929897-3b4e-4baa-b109-f37a31c12071', '4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'RFA-20260310-007', 500.00, 500.00, 'active', 'keenlenx ndiwa', 'keeenlenx@gmail.com', NULL, '2026-03-11', NULL, '1ee87751-8c00-4bde-a199-3756fa5682b3'),

-- Holiday special voucher (with redemptions)
('c8a57a80-4079-4786-a930-bccaa6a8b88f', 'eba70e22-b0e7-43f5-aa68-21369c7e263b', '11111111-1111-1111-1111-111111111111', 'RFA-20260218-41AF69B13A57AE45', 100.00, 0.00, 'redeemed', 'Elias', 'john@alias.com', '+254700000000', '2024-12-31', NULL, '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 8. Insert Redemptions (depends on vouchers, merchants, users)
-- ============================================================================
INSERT INTO redemptions (id, voucher_id, merchant_id, redeemed_by, amount_redeemed, previous_balance, new_balance, receipt_number, created_by) VALUES
-- First redemption for c8a57a80 (partial)
('542ef255-ce25-4f03-b158-0528ab0b7318', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', 'a0000000-0000-0000-0000-000000000001', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 50.00, 100.00, 50.00, 'REC-001', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
-- Second redemption for c8a57a80 (full)
('8477c470-bcea-45be-bf6d-f1c6cafeddeb', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', 'a0000000-0000-0000-0000-000000000001', NULL, 50.00, 50.00, 0.00, 'RCP20260219001', '1ee87751-8c00-4bde-a199-3756fa5682b3')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 9. Insert Transaction Log (depends on tenants)
-- ============================================================================
INSERT INTO transaction_log (id, transaction_type, source_type, source_id, from_tenant_id, to_tenant_id, amount, description, created_by) VALUES
('e9302f26-acde-4503-851c-8d0c7113b324', 'redemption', 'redemption', '542ef255-ce25-4f03-b158-0528ab0b7318', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 50.00, 'Voucher redemption at Java House', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('a44dce3b-4aae-4c8a-b838-4cdfe9ecfdc1', 'redemption', 'redemption', '8477c470-bcea-45be-bf6d-f1c6cafeddeb', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 50.00, 'Voucher redemption at Java House', '1ee87751-8c00-4bde-a199-3756fa5682b3')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 10. Insert Client Subscriptions (depends on tenants, billing_plans)
-- ============================================================================
INSERT INTO client_subscriptions (id, tenant_id, billing_plan_id, start_date, is_active, created_by) VALUES
('c0a80001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', '2026-01-01', true, '33333333-3333-3333-3333-333333333333'),
('c0a80002-0000-0000-0000-000000000002', 'b1e04148-1c41-415f-992c-8aacddb4498a', '22222222-2222-2222-2222-222222222221', '2026-02-01', true, '33333333-3333-3333-3333-333333333333')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 11. Insert Voucher Merchant Restrictions (depends on voucher_templates, merchants)
-- ============================================================================
INSERT INTO voucher_merchant_restrictions (voucher_template_id, merchant_id, created_by) VALUES
('f3b6eef4-312a-472e-b59a-90f47835608b', 'a0000000-0000-0000-0000-000000000001', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('f3b6eef4-312a-472e-b59a-90f47835608b', 'a0000000-0000-0000-0000-000000000002', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 'a0000000-0000-0000-0000-000000000001', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb')
ON CONFLICT (voucher_template_id, merchant_id) DO NOTHING;

-- ============================================================================
-- 12. Insert Invoices (depends on tenants)
-- ============================================================================
INSERT INTO invoices (id, invoice_number, tenant_id, billing_period_start, billing_period_end, issue_date, due_date, items, subtotal, total_amount, status, created_by) VALUES
('i0000000-0000-0000-0000-000000000001', 'INV-2026-03-001', '22222222-2222-2222-2222-222222222222', '2026-03-01', '2026-03-31', '2026-04-01', '2026-04-15', 
 '[{"description": "Monthly subscription fee", "quantity": 1, "unit_price": 49.00, "amount": 49.00}, {"description": "Voucher fees", "quantity": 150, "unit_price": 0.25, "amount": 37.50}]'::JSONB, 
 86.50, 86.50, 'issued', '33333333-3333-3333-3333-333333333333')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 13. Insert Settlements (depends on merchants)
-- ============================================================================
INSERT INTO settlements (id, settlement_number, merchant_id, period_start, period_end, total_redemptions, total_amount, rfa_fees, net_payable, status, created_by) VALUES
('s0000000-0000-0000-0000-000000000001', 'SET-2026-03-001', 'a0000000-0000-0000-0000-000000000001', '2026-03-01', '2026-03-15', 3, 150.00, 15.00, 135.00, 'paid', '33333333-3333-3333-3333-333333333333')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 14. Insert Audit Logs (depends on tenants, users)
-- ============================================================================
INSERT INTO audit_logs (id, tenant_id, user_id, action, entity_type, entity_id, old_values, new_values, ip_address) VALUES
('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'CREATE', 'voucher_template', 'f3b6eef4-312a-472e-b59a-90f47835608b', NULL, '{"name": "Tradewinds Lunch Voucher"}', '192.168.1.100'),
('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'REDEEM', 'voucher', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', '{"remaining": 100}', '{"remaining": 50}', '192.168.1.100')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- RE-ENABLE TRIGGERS (if disabled)
-- ============================================================================
-- SET session_replication_role = 'origin';

-- ============================================================================
-- Display Summary
-- ============================================================================
DO $$
DECLARE
    tenant_count INTEGER;
    user_count INTEGER;
    voucher_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO tenant_count FROM tenants;
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO voucher_count FROM vouchers;
    
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Seed Data Loaded Successfully!';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Tenants: %', tenant_count;
    RAISE NOTICE 'Users: %', user_count;
    RAISE NOTICE 'Vouchers: %', voucher_count;
    RAISE NOTICE '==========================================';
END $$;