# Use an official OpenJDK runtime as a parent image
FROM openjdk:11-jre-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY target/aiwebapp-1.0-SNAPSHOT.jar /app/aiwebapp.jar

# Make port 4567 available to the world outside this container
EXPOSE 4567

# Run the web service on container startup
CMD ["java", "-jar", "aiwebapp.jar"]
