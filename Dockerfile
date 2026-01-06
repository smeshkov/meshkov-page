# Use a lightweight Nginx image
FROM nginx:alpine

# Copy the custom configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 8080 (Cloud Run default)
EXPOSE 8080

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
