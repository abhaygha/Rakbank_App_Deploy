# Use an official JDK runtime as a parent image
FROM openjdk:17-jdk-alpine

# Set the working directory in the container
WORKDIR /app

RUN ls -l

RUN pwd

# Copy the application JAR file to the container
COPY target/com.rakbank_project-0.0.1-SNAPSHOT.jar /app/myapp.jar

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Run the application
ENTRYPOINT ["java","-jar","/app/myapp.jar"]
