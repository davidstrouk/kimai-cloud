FROM kimai/kimai2:apache

# Set proper permissions
RUN chown -R www-data:www-data /opt/kimai/var

# Add Render wrapper entrypoint that binds Apache to $PORT
COPY render-entrypoint.sh /usr/local/bin/render-entrypoint.sh
RUN chmod +x /usr/local/bin/render-entrypoint.sh

# Expose port (not required by Render, but harmless)
EXPOSE 8001

# Use the default entrypoint
CMD ["/usr/local/bin/render-entrypoint.sh"]
