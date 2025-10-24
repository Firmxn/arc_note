# Backend Structure Document for arc_note

## 1. Backend Architecture

Our backend follows a simple, maintainable design while still allowing us to handle more users and features as the app grows. Here’s how it’s organized:

- **Monolithic REST API (Express.js)**
  - All backend logic lives in a single codebase, making it easy to navigate and deploy.
  - Follows the Model–View–Controller (MVC) pattern:
    - Models define how data is structured and interact with the database.
    - Controllers handle incoming requests, orchestrate business logic, and return responses.
    - Routes map HTTP requests (like GET or POST) to controller methods.
- **Scalability & Performance**
  - We can split parts of the monolith into microservices if needed (for example, a separate service for real-time updates).
  - Using caching (Redis) reduces load on the database and speeds up repeated queries.
  - Connection pooling ensures the database isn’t overwhelmed by too many simultaneous requests.
- **Maintainability**
  - Clear folder structure separates routes, controllers, models, and utility functions.
  - Configuration files (for environment variables, database credentials, etc.) are centralized.
  - Automated linting and formatting keep the code consistent.

## 2. Database Management

We store structured data in a relational database and use a fast in-memory store for caching:

- **Primary Database**
  - Type: SQL (relational)
  - System: PostgreSQL (managed by AWS RDS)
  - Benefits: strong data integrity, ACID transactions, flexible querying with SQL
- **Cache**
  - Type: NoSQL (key-value)
  - System: Redis (managed by AWS ElastiCache)
  - Usage: temporarily stores frequently accessed data (like user sessions or recent notes) to speed up responses
- **Data Access & Management**
  - An ORM (Sequelize) handles SQL queries in JavaScript, mapping tables to model classes.
  - Database migrations (using Sequelize CLI) keep schema changes versioned and reversible.
  - Regular backups are configured in RDS, with point-in-time recovery enabled.

## 3. Database Schema

Below is our main database structure in human-readable form, followed by the SQL definition. It includes users, notes, and tags.

### Human-Readable Schema

- **Users**
  - id: unique user identifier
  - email: user’s email (unique)
  - password_hash: encrypted password
  - created_at / updated_at: timestamps

- **Notes**
  - id: unique note identifier
  - user_id: reference to the note’s owner (Users.id)
  - title: short text title
  - content: main text body
  - created_at / updated_at: timestamps

- **Tags**
  - id: unique tag identifier
  - name: tag label (e.g., "work", "personal")

- **NoteTags (join table)**
  - note_id: reference to Notes.id
  - tag_id: reference to Tags.id

### SQL Schema (PostgreSQL)

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE notes (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE tags (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE note_tags (
  note_id INTEGER REFERENCES notes(id) ON DELETE CASCADE,
  tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (note_id, tag_id)
);
```  

## 4. API Design and Endpoints

We use a RESTful approach, where each resource (users, notes, tags) has its own URL and standard HTTP methods.

### Key Endpoints

- **Authentication & Users**
  - POST `/api/auth/register` : create a new user account
  - POST `/api/auth/login`    : sign in and receive a JWT token
  - GET `/api/users/me`       : get profile info (requires token)

- **Notes**
  - GET `/api/notes`          : list all notes for the logged-in user
  - POST `/api/notes`         : create a new note
  - GET `/api/notes/:id`      : retrieve one note by ID
  - PUT `/api/notes/:id`      : update a note
  - DELETE `/api/notes/:id`   : delete a note

- **Tags**
  - GET `/api/tags`           : list all available tags
  - POST `/api/tags`          : create a new tag

- **Associations**
  - POST `/api/notes/:id/tags`    : add tags to a note
  - DELETE `/api/notes/:id/tags/:tagId` : remove a tag from a note

### How Frontend Talks to Backend

- The mobile/desktop app sends HTTP requests with JSON payloads.
- Protected routes require a JWT in the `Authorization` header.
- Responses follow a standard structure:
  ```json
  {
    "success": true,
    "data": { /* requested data */ }
  }
  ```

## 5. Hosting Solutions

We host our backend entirely on Amazon Web Services (AWS) to balance reliability, scalability, and cost:

- **Compute**
  - AWS Elastic Beanstalk runs the Node.js application in managed EC2 instances.
  - Auto-scaling groups adjust instance count based on CPU and request load.
- **Database**
  - AWS RDS for PostgreSQL provides automated backups, patching, and multi-AZ failover.
- **Cache**
  - AWS ElastiCache (Redis) handles in-memory data storage for sessions and hot data.
- **Storage**
  - AWS S3 stores any file attachments or exported notes, with lifecycle rules for cleanup.

Benefits:
- No server maintenance overhead.
- Easy scaling up or down.
- Pay only for what we use.

## 6. Infrastructure Components

- **Load Balancer (AWS ELB)**
  - Distributes incoming traffic across multiple EC2 instances in Elastic Beanstalk.
- **Content Delivery Network (AWS CloudFront)**
  - Speeds up delivery of static assets (like images or exported PDFs) by caching them globally.
- **Caching (Redis)**
  - Caches session data and frequent queries to reduce database load.
- **Containerization (Docker)**
  - Each release is packaged as a Docker image, ensuring consistent behavior across development and production.
- **CI/CD Pipeline (GitHub Actions)**
  - Automatically builds, tests, and deploys code to Elastic Beanstalk when changes are merged into `main`.

## 7. Security Measures

- **Authentication & Authorization**
  - JSON Web Tokens (JWT) secure protected endpoints.
  - Passwords are hashed with bcrypt before storing in the database.
- **Data Encryption**
  - HTTPS everywhere—SSL certificates managed by AWS Certificate Manager.
  - RDS encryption at rest for the PostgreSQL database.
- **Network Security**
  - Security groups restrict access to only necessary ports (HTTP/HTTPS inbound, database port limited to backend servers).
- **Input Validation & Sanitization**
  - All incoming data is validated (using Joi) to prevent SQL injection and other attacks.
- **Compliance**
  - Automated vulnerability scans run weekly.
  - Logging of security-related events for audit and forensic purposes.

## 8. Monitoring and Maintenance

- **Performance Monitoring**
  - AWS CloudWatch tracks CPU, memory, and response times.
  - New Relic (or Datadog) provides detailed request-tracing and alerting.
- **Logging**
  - Structured logs (JSON) are sent to CloudWatch Logs and aggregated in an ELK stack for searching and alerting.
- **Error Tracking**
  - Sentry captures unhandled errors and notifies the dev team.
- **Maintenance Practices**
  - Database migrations are reviewed and tested in a staging environment.
  - Dependencies are updated monthly, with automated tests to catch regressions.
  - Regular security patching for the OS and runtime.

## 9. Conclusion and Overall Backend Summary

The backend for arc_note is designed to be simple to start with but flexible enough to grow as new needs emerge. It uses a familiar RESTful API structure, a reliable PostgreSQL database, and fast Redis caching. Hosting on AWS gives us rock-solid reliability, automatic scaling, and integrated security features.

This setup aligns with our goals:
- **Ease of Development:** Clear folder structure, automated tests, and CI/CD pipeline get changes into production quickly.
- **Scalability:** Elastic Beanstalk auto-scaling and distributed caching ensure smooth performance under load.
- **Security & Compliance:** Industry-standard practices around encryption, authentication, and monitoring protect user data.

As arc_note evolves from a simple counter to a full-featured note-taking app, this backend structure provides a solid foundation. Developers can focus on adding features—like collaborative editing or file attachments—without worrying about reinventing the core infrastructure.