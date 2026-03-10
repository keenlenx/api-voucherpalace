#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DB_CONTAINER="voucher-db"
DB_USER="voucherpalace"
DB_NAME="voucherpalace"
SEED_FILE="database/seed.sql"

# Help function
show_help() {
    echo -e "${BLUE}Usage:${NC} ./seed.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE     Specify custom seed file (default: database/seed.sql)"
    echo "  -c, --container NAME Specify container name (default: voucher-db)"
    echo "  -u, --user USER     Specify database user (default: keenlenx)"
    echo "  -d, --database DB   Specify database name (default: voucherpalace)"
    echo "  -p, --preview       Preview SQL without executing"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Example:"
    echo "  ./seed.sh"
    echo "  ./seed.sh -f custom-seed.sql"
    echo "  ./seed.sh --preview"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            SEED_FILE="$2"
            shift 2
            ;;
        -c|--container)
            DB_CONTAINER="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -p|--preview)
            PREVIEW_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Banner
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    Voucher Platform Database Seeder v1.0   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

# Preview mode
if [ "$PREVIEW_MODE" = true ]; then
    echo -e "${YELLOW}📄 Preview Mode - Showing first 20 lines of seed file:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    head -n 20 "$SEED_FILE"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${YELLOW}Total lines: $(wc -l < "$SEED_FILE")${NC}"
    exit 0
fi

# Check if seed file exists
if [ ! -f "$SEED_FILE" ]; then
    echo -e "${RED}❌ Error: $SEED_FILE not found!${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running!${NC}"
    exit 1
fi

# Check if container is running
if ! docker ps | grep -q "$DB_CONTAINER"; then
    echo -e "${YELLOW}⚠️  Container $DB_CONTAINER is not running.${NC}"
    read -p "Do you want to start Docker Compose? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🚀 Starting Docker Compose...${NC}"
        docker-compose up -d
        sleep 5
    else
        echo -e "${RED}❌ Exiting.${NC}"
        exit 1
    fi
fi

# Show file info
FILE_SIZE=$(du -h "$SEED_FILE" | cut -f1)
LINE_COUNT=$(wc -l < "$SEED_FILE")
echo -e "${BLUE}📁 Seed file:${NC} $SEED_FILE ($FILE_SIZE, $LINE_COUNT lines)"

# Confirm with user
echo -e "${YELLOW}⚠️  This will seed data into:${NC} $DB_CONTAINER/$DB_NAME"
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Seeding cancelled.${NC}"
    exit 0
fi

# Copy seed file to container
echo -e "${YELLOW}📦 Copying seed file to container...${NC}"
docker cp "$SEED_FILE" "$DB_CONTAINER":/tmp/seed.sql

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to copy seed file${NC}"
    exit 1
fi

# Run the seed file
echo -e "${YELLOW}🌱 Seeding database...${NC}"

# Create a temporary file for output
TEMP_OUTPUT=$(mktemp)

# Run the seed and capture output
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f /tmp/seed.sql > "$TEMP_OUTPUT" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database seeded successfully!${NC}"
    
    # Show summary
    echo -e "\n${GREEN}📊 Database Summary:${NC}"
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            (SELECT COUNT(*) FROM tenants) as tenants,
            (SELECT COUNT(*) FROM users) as users,
            (SELECT COUNT(*) FROM merchants) as merchants,
            (SELECT COUNT(*) FROM voucher_templates) as templates,
            (SELECT COUNT(*) FROM vouchers) as vouchers,
            (SELECT COUNT(*) FROM redemptions) as redemptions;
    "
else
    echo -e "${RED}❌ Seeding failed!${NC}"
    echo -e "${YELLOW}Last 20 lines of error:${NC}"
    tail -n 20 "$TEMP_OUTPUT"
    
    # Ask if user wants to see full error
    read -p "Show full error log? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cat "$TEMP_OUTPUT"
    fi
    
    rm -f "$TEMP_OUTPUT"
    exit 1
fi

# Clean up
echo -e "${YELLOW}🧹 Cleaning up...${NC}"
docker exec "$DB_CONTAINER" rm -f /tmp/seed.sql
rm -f "$TEMP_OUTPUT"

echo -e "${GREEN}========================================${NC}"
