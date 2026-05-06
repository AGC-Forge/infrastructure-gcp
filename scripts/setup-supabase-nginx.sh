#!/bin/bash

echo "Setting up Supabase Nginx Configuration..."

# 1. Create log directory
sudo mkdir -p /var/log/nginx
sudo chown -R www-data:www-data /var/log/nginx

# 2. Generate SSL certificates
echo "Generating SSL certificates..."
bash scripts/generate-supabase-ssl.sh

# 3. Copy configuration
echo "Copying Nginx configuration..."
sudo cp nginx/supabase.conf /etc/nginx/sites-available/supabase.conf

# 4. Create symlink
echo "Enabling site..."
sudo ln -sf /etc/nginx/sites-available/supabase.conf /etc/nginx/sites-enabled/

# 5. Add domain to hosts file (for local development)
echo "Adding domains to /etc/hosts..."
if ! grep -q "api-supabase.localtunnel.it.com" /etc/hosts; then
    echo "127.0.0.1 api-supabase.localtunnel.it.com" | sudo tee -a /etc/hosts
    echo "127.0.0.1 studio-supabase.localtunnel.it.com" | sudo tee -a /etc/hosts
    echo "127.0.0.1 realtime-supabase.localtunnel.it.com" | sudo tee -a /etc/hosts
fi

# 6. Test configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# 7. Reload Nginx
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo ""
echo "✅ Supabase Nginx setup complete!"
echo ""
echo "Access your Supabase services at:"
echo "  Studio:  https://studio-supabase.localtunnel.it.com"
echo "  API:     https://api-supabase.localtunnel.it.com"
echo "  Realtime: wss://realtime-supabase.localtunnel.it.com"
echo ""
echo "For production, replace 'localtunnel.it.com' with your actual domain."
