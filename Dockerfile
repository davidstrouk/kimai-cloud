FROM kimai/kimai2:apache

# Set proper permissions
RUN chown -R www-data:www-data /opt/kimai/var

# Expose port 8001 (Kimai's internal port)
EXPOSE 8001

# Use the default entrypoint
CMD ["/entrypoint.sh"]
