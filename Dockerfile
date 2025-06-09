# Stage 1: Build the application
# Use a base image with JDK for compiling the application
FROM eclipse-temurin:17-jdk-jammy AS builder
WORKDIR /app

# Copy the Maven wrapper scripts and properties
# Ensure mvnw is executable
COPY .mvn/wrapper/maven-wrapper.properties .mvn/wrapper/maven-wrapper.properties
COPY mvnw .
RUN chmod +x ./mvnw

# Copy the pom.xml file to download dependencies
COPY pom.xml .

# Download dependencies to leverage Docker cache
RUN ./mvnw dependency:resolve

# Copy the rest of the application source code
COPY src ./src

# Package the application, skipping tests for a faster build
RUN ./mvnw package -DskipTests

# Stage 2: Create the runtime image
# Use a JRE base image for a smaller footprint
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Create a non-root user and group for security
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser

# Switch to the non-root user
USER appuser

# Copy the built JAR file from the builder stage
COPY --from=builder /app/target/discovery-service-0.0.1-SNAPSHOT.jar app.jar

# Expose the port the application will run on.
# Your application.properties uses server.port=${PORT}, so the actual port
# will be set by the PORT environment variable at runtime.
# 8761 is the default port for Eureka and is used here for documentation.
EXPOSE 8761

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]