-- ============================================================================
-- Romeo Fox Alpha Voucher Management Platform - Seed Data
-- Compatible with Complete Schema
-- ============================================================================

-- Connect to the database
\connect voucherpalace

-- ============================================================================
-- 1. Insert Tenants (no dependencies)
-- ============================================================================
INSERT INTO tenants (id, tenant_name, tenant_type, email, phone, status, wallet_balance, credit_limit) VALUES
('11111111-1111-1111-1111-111111111111', 'Romeo Fox Alpha Limited', 'rfa_internal', 'system@romeofoxalpha.com', NULL, 'active', 1000000.00, 500000.00),
('22222222-2222-2222-2222-222222222222', 'Kenya Airways', 'corporate', 'hr@kenya-airways.com', '+254207111111', 'active', 500000.00, 200000.00),
('b1e04148-1c41-415f-992c-8aacddb4498a', 'National Bank', 'corporate', 'info@nationalbank.co.ke', '0702000222', 'active', 750000.00, 300000.00),
('3e0d8385-9c7a-4462-a009-63fdd514da8e', 'Kool Cutz', 'corporate', 'info@koolcutz.com', '0724727181', 'active', 100000.00, 50000.00),
('6cba5fa0-2099-4c33-9157-8773ebf756de', 'Hot Foods', 'merchant', 'info@hotfoods.co.ke', '0768908987', 'active', 0.00, 0.00)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. Insert Billing Plans
-- ============================================================================
INSERT INTO billing_plans (id, plan_name, plan_code, plan_type, description, monthly_fixed_fee, per_voucher_fee, transaction_percentage, features, is_public, is_active) VALUES
('22222222-2222-2222-2222-222222222221', 'Starter', 'STARTER', 'pay_as_you_go', 'Pay only for what you use', 0.00, 0.50, 2.00, '{"reports": "basic", "max_users": 5, "api_access": false}', true, true),
('22222222-2222-2222-2222-222222222222', 'Professional', 'PRO', 'hybrid', 'For growing businesses', 49.00, 0.25, 1.50, '{"reports": "advanced", "max_users": 20, "api_access": true, "bulk_upload": true}', true, true),
('22222222-2222-2222-2222-222222222223', 'Enterprise', 'ENTERPRISE', 'subscription', 'Custom solutions for large organizations', 199.00, 0.10, 1.00, '{"reports": "custom", "max_users": -1, "api_access": true, "dedicated_support": true, "white_label": true}', true, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 3. Insert Users
-- Note: Password hashes are for demo purposes
-- Password for most users: 'password123' (hashed with bcrypt)
-- ============================================================================
INSERT INTO users (id, tenant_id, email, password_hash, first_name, last_name, phone, role, is_email_verified, status, mfa_enabled) VALUES
-- Super Admin
('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'admin@romeofoxalpha.com', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'System', 'Administrator', NULL, 'super_admin', true, 'active', false),

-- Client Admins
('98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', '11111111-1111-1111-1111-111111111111', 'brian@romeofoxalpha.com', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'Brian', 'Ndiwa', '+254704611605', 'client_admin', true, 'active', false),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', 'admin@safaricom.co.ke', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'John', 'Kamau', '+254722123456', 'client_admin', true, 'active', false),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '22222222-2222-2222-2222-222222222222', 'admin@kenya-airways.com', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'Sarah', 'Odhiambo', '+254733123456', 'client_admin', true, 'active', false),
('cccccccc-cccc-cccc-cccc-ccccccccccc1', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'admin@nationalbank.co.ke', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'James', 'Mwangi', '+254744123456', 'client_admin', true, 'active', false),

-- Merchants Admins
('dddddddd-dddd-dddd-dddd-ddddddddddd1', '6cba5fa0-2099-4c33-9157-8773ebf756de', 'manager@hotfoods.co.ke', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'Ken', 'Odhiambo', '+254755123456', 'merchant_admin', true, 'active', false),

-- Consumers
('1ee87751-8c00-4bde-a199-3756fa5682b3', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'bdiwa@gmail.com', '$2b$10$O8Ss9F5T9ZEXnUdqf.SQy.02dnd/bqvsCdE8Pm6wCi52cUTLU7M8G', 'Brian', 'K', '0704611605', 'consumer', true, 'active', false),
('dabf03af-a6fa-46c5-aaea-01c7a99bbc13', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'consumer1@example.com', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'John', 'Doe', '0712345678', 'consumer', true, 'active', false),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee1', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'consumer2@example.com', '$2b$10$X7VYx8Qn7nY9xK9l9M9n9eX7VYx8Qn7nY9xK9l9M9', 'Jane', 'Smith', '0798765432', 'consumer', true, 'active', false)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- 4. Insert Merchants
-- ============================================================================
INSERT INTO merchants (id, tenant_id, merchant_name, merchant_code, merchant_category, email, phone, settlement_period, is_active) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '11111111-1111-1111-1111-111111111111', 'Test Restaurant', 'TEST001', 'Restaurant', 'restaurant@test.com', '+254700111222', 'weekly', true),
('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Java House', 'JAVA01', 'Restaurant', 'payments@javahouse.co.ke', '+254700111333', 'weekly', true),
('a0000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'KFC - Airways', 'KFC001', 'Fast Food', 'kfc@kenya-airways.com', '+254700111444', 'weekly', true),
('a0000000-0000-0000-0000-000000000003', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'National Bank Staff Canteen', 'NBK001', 'Cafeteria', 'canteen@nationalbank.co.ke', '+254700111555', 'weekly', true),
('a0000000-0000-0000-0000-000000000004', '6cba5fa0-2099-4c33-9157-8773ebf756de', 'Hot Foods - CBD', 'HOT001', 'Restaurant', 'info@hotfoods.co.ke', '+254700111666', 'daily', true),
('a0000000-0000-0000-0000-000000000005', '6cba5fa0-2099-4c33-9157-8773ebf756de', 'Hot Foods - Westlands', 'HOT002', 'Restaurant', 'westlands@hotfoods.co.ke', '+254700111777', 'daily', true)
ON CONFLICT (merchant_code) DO NOTHING;

-- ============================================================================
-- 5. Insert Voucher Templates
-- ============================================================================
INSERT INTO voucher_templates (id, tenant_id, template_name, description, voucher_type, value_amount, valid_from, valid_to, usage_limit_type, is_public_visible, public_price, background_color, text_color) VALUES
('77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'Test Voucher', 'Basic test voucher for development', 'fixed_amount', 100.00, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 'single', false, NULL, '#FFFFFF', '#000000'),

('f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'Tradewinds Lunch Voucher', 'KSH 300 lunch voucher at Java House', 'fixed_amount', 300.00, '2026-01-01', '2026-12-31', 'multi', true, 300.00, '#FF6B6B', '#FFFFFF'),

('f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'Staff Lunch Voucher', 'Daily lunch at partner restaurants', 'fixed_amount', 500.00, '2026-01-01', '2026-12-31', 'single', true, 500.00, '#4ECDC4', '#FFFFFF'),

('4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'National Bank Lunch', '500 KES lunch voucher for staff', 'fixed_amount', 500.00, '2026-01-01', '2026-12-31', 'multi', true, 500.00, '#45B7D1', '#FFFFFF'),

('4e285168-c478-403c-bb0e-278c11c0b743', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'March Staff Lunch', 'March 2026 special lunch', 'fixed_amount', 500.00, '2026-03-01', '2026-03-31', 'single', false, NULL, '#96CEB4', '#000000'),

('eba70e22-b0e7-43f5-aa68-21369c7e263b', '11111111-1111-1111-1111-111111111111', 'Holiday Special', '20% off at participating restaurants', 'percentage', NULL, '2026-12-01', '2026-12-31', 'single', true, 100.00, '#FFEAA7', '#000000', 20.00)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 6. Insert Voucher Batches
-- ============================================================================
INSERT INTO voucher_batches (id, tenant_id, batch_reference, voucher_template_id, total_count, successful_count, status, created_by) VALUES
('7f443cc1-68bc-4b24-b417-807a8efc6b81', '11111111-1111-1111-1111-111111111111', 'BATCH-20260315-001', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 100, 100, 'completed', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('b5080460-6d5e-4b6f-b1e9-8fbc8fd74eb5', '11111111-1111-1111-1111-111111111111', 'BATCH-20260315-002', 'f3b6eef4-312a-472e-b59a-90f47835608b', 50, 50, 'completed', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('c6091572-7e6f-4b8d-9c3a-2d4e5f6a7b8c', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'BATCH-20260315-003', '4408beb3-ced9-4815-aca1-b08babafd7c9', 200, 200, 'completed', '1ee87751-8c00-4bde-a199-3756fa5682b3')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 7. Insert Vouchers
-- ============================================================================
INSERT INTO vouchers (id, voucher_template_id, tenant_id, code, original_value, remaining_value, status, beneficiary_name, beneficiary_email, expires_at, batch_id, created_by, distribution_method) VALUES
-- Test vouchers
('88888888-8888-8888-8888-888888888881', '77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'TEST-001', 100.00, 100.00, 'active', 'Test User', 'test@example.com', CURRENT_DATE + INTERVAL '30 days', NULL, '33333333-3333-3333-3333-333333333333', 'email'),
('88888888-8888-8888-8888-888888888882', '77777777-7777-7777-7777-777777777771', '11111111-1111-1111-1111-111111111111', 'TEST-002', 100.00, 50.00, 'active', 'Partial User', 'partial@example.com', CURRENT_DATE + INTERVAL '30 days', NULL, '33333333-3333-3333-3333-333333333333', 'email'),

-- Tradewinds vouchers
('6f63b97a-3d53-40c8-85ed-be744cd5a242', 'f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'TRA-001', 300.00, 300.00, 'active', 'John Doe', 'john.doe@kenya-airways.com', '2026-12-31', 'b5080460-6d5e-4b6f-b1e9-8fbc8fd74eb5', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'email'),
('6f63b97a-3d53-40c8-85ed-be744cd5a243', 'f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'TRA-002', 300.00, 300.00, 'active', 'Jane Smith', 'jane.smith@kenya-airways.com', '2026-12-31', 'b5080460-6d5e-4b6f-b1e9-8fbc8fd74eb5', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'email'),

-- Staff lunch vouchers
('4ab98fc7-4595-4b65-a65c-62a10467b909', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-001', 500.00, 500.00, 'active', 'Michael Ochieng', 'michael.ochieng@rfa.com', '2026-12-31', '7f443cc1-68bc-4b24-b417-807a8efc6b81', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'email'),
('4ab98fc7-4595-4b65-a65c-62a10467b910', 'f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', '11111111-1111-1111-1111-111111111111', 'STA-002', 500.00, 500.00, 'active', 'Lucy Wanjiku', 'lucy.wanjiku@rfa.com', '2026-12-31', '7f443cc1-68bc-4b24-b417-807a8efc6b81', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'email'),

-- National Bank vouchers
('53a7923c-4c5c-461f-9aad-5d075301fe33', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'NBK-001', 500.00, 500.00, 'active', 'Peter Kimani', 'peter.kimani@nationalbank.co.ke', '2026-12-30', 'c6091572-7e6f-4b8d-9c3a-2d4e5f6a7b8c', '1ee87751-8c00-4bde-a199-3756fa5682b3', 'email'),
('53a7923c-4c5c-461f-9aad-5d075301fe34', '4408beb3-ced9-4815-aca1-b08babafd7c9', 'b1e04148-1c41-415f-992c-8aacddb4498a', 'NBK-002', 500.00, 500.00, 'active', 'Mary Akinyi', 'mary.akinyi@nationalbank.co.ke', '2026-12-30', 'c6091572-7e6f-4b8d-9c3a-2d4e5f6a7b8c', '1ee87751-8c00-4bde-a199-3756fa5682b3', 'email'),

-- Redeemed voucher (for testing redemptions)
('c8a57a80-4079-4786-a930-bccaa6a8b88f', 'f3b6eef4-312a-472e-b59a-90f47835608b', '11111111-1111-1111-1111-111111111111', 'TRA-RDM-001', 300.00, 0.00, 'redeemed', 'Demo User', 'demo@example.com', '2026-12-31', NULL, '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'email')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 8. Insert Redemptions
-- ============================================================================
INSERT INTO redemptions (id, voucher_id, merchant_id, redeemed_by, amount_redeemed, previous_balance, new_balance, redemption_method, receipt_number, status, created_by) VALUES
-- First redemption for c8a57a80 (partial)
('542ef255-ce25-4f03-b158-0528ab0b7318', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', 'a0000000-0000-0000-0000-000000000001', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 150.00, 300.00, 150.00, 'qr_scan', 'RCP-20260315-001', 'completed', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),

-- Second redemption for c8a57a80 (full)
('8477c470-bcea-45be-bf6d-f1c6cafeddeb', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', 'a0000000-0000-0000-0000-000000000001', '1ee87751-8c00-4bde-a199-3756fa5682b3', 150.00, 150.00, 0.00, 'code_entry', 'RCP-20260315-002', 'completed', '1ee87751-8c00-4bde-a199-3756fa5682b3'),

-- Redemption for a partial voucher
('98765432-1111-2222-3333-444455556666', '88888888-8888-8888-8888-888888888882', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 25.00, 50.00, 25.00, 'qr_scan', 'RCP-20260315-003', 'completed', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 9. Insert Transaction Log
-- ============================================================================
INSERT INTO transaction_log (id, transaction_type, source_type, source_id, from_tenant_id, to_tenant_id, amount, fee_amount, description, created_by) VALUES
('a44dce3b-4aae-4c8a-b838-4cdfe9ecfdc1', 'redemption', 'redemption', '542ef255-ce25-4f03-b158-0528ab0b7318', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 150.00, 7.50, 'Voucher redemption at Java House', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('b55dce3b-4aae-4c8a-b838-4cdfe9ecfdc2', 'redemption', 'redemption', '8477c470-bcea-45be-bf6d-f1c6cafeddeb', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 150.00, 7.50, 'Voucher redemption at Java House', '1ee87751-8c00-4bde-a199-3756fa5682b3'),
('c66dce3b-4aae-4c8a-b838-4cdfe9ecfdc3', 'redemption', 'redemption', '98765432-1111-2222-3333-444455556666', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 25.00, 1.25, 'Voucher redemption at Test Restaurant', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 10. Insert Client Subscriptions
-- ============================================================================
INSERT INTO client_subscriptions (id, tenant_id, billing_plan_id, start_date, is_active, created_by) VALUES
('c0a80001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', '2026-01-01', true, '33333333-3333-3333-3333-333333333333'),
('c0a80002-0000-0000-0000-000000000002', 'b1e04148-1c41-415f-992c-8aacddb4498a', '22222222-2222-2222-2222-222222222221', '2026-02-01', true, '33333333-3333-3333-3333-333333333333'),
('c0a80003-0000-0000-0000-000000000003', '6cba5fa0-2099-4c33-9157-8773ebf756de', '22222222-2222-2222-2222-222222222221', '2026-03-01', true, '33333333-3333-3333-3333-333333333333')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 11. Insert Voucher Merchant Restrictions
-- ============================================================================
INSERT INTO voucher_merchant_restrictions (voucher_template_id, merchant_id, created_by) VALUES
-- Tradewinds vouchers can be used at Java House and KFC
('f3b6eef4-312a-472e-b59a-90f47835608b', 'a0000000-0000-0000-0000-000000000001', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('f3b6eef4-312a-472e-b59a-90f47835608b', 'a0000000-0000-0000-0000-000000000002', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),

-- Staff lunch vouchers can be used at Java House and Test Restaurant
('f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 'a0000000-0000-0000-0000-000000000001', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),
('f5e51d0e-76a7-4a0c-ba73-4b824e907a9a', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb'),

-- National Bank vouchers can be used at their canteen
('4408beb3-ced9-4815-aca1-b08babafd7c9', 'a0000000-0000-0000-0000-000000000003', '1ee87751-8c00-4bde-a199-3756fa5682b3')
ON CONFLICT (voucher_template_id, merchant_id) DO NOTHING;

-- ============================================================================
-- 12. Insert Invoices
-- ============================================================================
INSERT INTO invoices (id, invoice_number, tenant_id, billing_period_start, billing_period_end, issue_date, due_date, items, subtotal, tax_amount, total_amount, status, created_by) VALUES
('f0000000-1111-2222-3333-444455556666', 'INV-2026-03-001', '22222222-2222-2222-2222-222222222222', '2026-03-01', '2026-03-31', '2026-04-01', '2026-04-15', 
 '[{"description": "Monthly subscription - Professional Plan", "quantity": 1, "unit_price": 49.00, "amount": 49.00}, {"description": "Voucher fees (150 vouchers)", "quantity": 150, "unit_price": 0.25, "amount": 37.50}]'::JSONB, 
 86.50, 8.65, 95.15, 'issued', '33333333-3333-3333-3333-333333333333'),

('f0000000-1111-2222-3333-444455556667', 'INV-2026-03-002', 'b1e04148-1c41-415f-992c-8aacddb4498a', '2026-03-01', '2026-03-31', '2026-04-01', '2026-04-15', 
 '[{"description": "Monthly subscription - Starter Plan", "quantity": 1, "unit_price": 0.00, "amount": 0.00}, {"description": "Voucher fees (200 vouchers)", "quantity": 200, "unit_price": 0.50, "amount": 100.00}]'::JSONB, 
 100.00, 16.00, 116.00, 'issued', '33333333-3333-3333-3333-333333333333')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 13. Insert Settlements
-- ============================================================================
INSERT INTO settlements (id, settlement_number, merchant_id, period_start, period_end, total_redemptions, total_amount, rfa_fees, net_payable, status, created_by) VALUES
('g0000000-1111-2222-3333-444455556666', 'SET-2026-03-001', 'a0000000-0000-0000-0000-000000000001', '2026-03-01', '2026-03-15', 3, 325.00, 16.25, 308.75, 'paid', '33333333-3333-3333-3333-333333333333'),
('g0000000-1111-2222-3333-444455556667', 'SET-2026-03-002', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '2026-03-01', '2026-03-15', 1, 25.00, 1.25, 23.75, 'pending', '33333333-3333-3333-3333-333333333333')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 14. Insert Audit Logs
-- ============================================================================
INSERT INTO audit_logs (id, tenant_id, user_id, action, entity_type, entity_id, old_values, new_values, ip_address) VALUES
('h0000000-1111-2222-3333-444455556666', '11111111-1111-1111-1111-111111111111', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'CREATE', 'voucher_template', 'f3b6eef4-312a-472e-b59a-90f47835608b', NULL, '{"name": "Tradewinds Lunch Voucher", "value": 300}', '192.168.1.100'),
('h0000000-1111-2222-3333-444455556667', '11111111-1111-1111-1111-111111111111', '98ff8b8f-f15f-4a6e-aaf7-47f6ef67ecdb', 'REDEEM', 'voucher', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', '{"remaining": 300}', '{"remaining": 150}', '192.168.1.100'),
('h0000000-1111-2222-3333-444455556668', '11111111-1111-1111-1111-111111111111', '1ee87751-8c00-4bde-a199-3756fa5682b3', 'REDEEM', 'voucher', 'c8a57a80-4079-4786-a930-bccaa6a8b88f', '{"remaining": 150}', '{"remaining": 0}', '192.168.1.101')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 15. Display Summary
-- ============================================================================
DO $$
DECLARE
    tenant_count INTEGER;
    user_count INTEGER;
    merchant_count INTEGER;
    template_count INTEGER;
    voucher_count INTEGER;
    redemption_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO tenant_count FROM tenants;
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO merchant_count FROM merchants;
    SELECT COUNT(*) INTO template_count FROM voucher_templates;
    SELECT COUNT(*) INTO voucher_count FROM vouchers;
    SELECT COUNT(*) INTO redemption_count FROM redemptions;
    
    RAISE NOTICE '╔══════════════════════════════════════════╗';
    RAISE NOTICE '║     Seed Data Loaded Successfully!      ║';
    RAISE NOTICE '╠══════════════════════════════════════════╣';
    RAISE NOTICE '║ Tenants:        %', LPAD(tenant_count::text, 12);
    RAISE NOTICE '║ Users:          %', LPAD(user_count::text, 12);
    RAISE NOTICE '║ Merchants:      %', LPAD(merchant_count::text, 12);
    RAISE NOTICE '║ Templates:      %', LPAD(template_count::text, 12);
    RAISE NOTICE '║ Vouchers:       %', LPAD(voucher_count::text, 12);
    RAISE NOTICE '║ Redemptions:    %', LPAD(redemption_count::text, 12);
    RAISE NOTICE '╚══════════════════════════════════════════╝';
END $$;