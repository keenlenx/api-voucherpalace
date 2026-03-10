#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Voucher Platform Database Seeder    ${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if seed.sql exists
if [ ! -f "database/backups/seed.sql" ]; then
    echo -e "${RED}❌ Error: database/seed.sql not found!${NC}"
    echo -e "Please make sure seed.sql is in the database directory."
    exit 1
fi

# Check if docker container is running
if ! docker ps | grep -q voucher-db; then
    echo -e "${RED}❌ Error: voucher-db container is not running!${NC}"
    echo -e "Please start your Docker containers first:"
    echo -e "  docker-compose up -d"
    exit 1
fi

echo -e "${YELLOW}📦 Copying seed.sql to container...${NC}"
docker cp database/seed.sql voucher-db:/tmp/seed.sql

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to copy seed.sql to container${NC}"
    exit 1
fi

echo -e "${YELLOW}🌱 Seeding database...${NC}"
docker exec -i voucher-db psql -U keenlenx -d voucherpalace -f /tmp/seed.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database seeded successfully!${NC}"
    
    # Show summary
    echo -e "\n${GREEN}📊 Database Summary:${NC}"
    docker exec voucher-db psql -U keenlenx -d voucherpalace -c "
        SELECT 
            (SELECT COUNT(*) FROM tenants) as tenants,
            (SELECT COUNT(*) FROM users) as users,
            (SELECT COUNT(*) FROM merchants) as merchants,
            (SELECT COUNT(*) FROM voucher_templates) as templates,
            (SELECT COUNT(*) FROM vouchers) as vouchers;
    "
else
    echo -e "${RED}❌ Seeding failed!${NC}"
    exit 1
fi

# Clean up
echo -e "${YELLOW}🧹 Cleaning up...${NC}"
docker exec voucher-db rm -f /tmp/seed.sql

echo -e "${GREEN}========================================${NC}"
