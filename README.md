# QuickWork

A comprehensive property rental management system built with .NET Core backend and Flutter frontend applications.

## 📱 Applications

QuickWork system consists of three Flutter applications:

1. **Desktop Admin App** (`QuickWork_Admin`) - Administrative interface for system management
2. **Landlord Desktop App** (`QuickWork_Desktop`) - Property management interface
3. **Mobile App** (QuickWork_Mobile`) - Mobile application for regular users to browse and post jobs

## 🔐 Test Login Credentials

### Desktop Admin App
- **Username:** `admin` (pre-filled)
- **Password:** `qwerty` (pre-filled)

### Landlord Desktop App
- **Username:** `berinm` (pre-filled)
- **Password:** `test` (pre-filled)

### Mobile App
- **Username:** `berinm` (pre-filled)
- **Password:** `test` (pre-filled)

> **Note:** All login forms come with pre-filled test credentials for easy testing.

## 📧 Email Notifications

### Landlord Notification Email
The system uses the following email account for sending notifications to landlords:

- **Email:** ``
- **Password:** ``

This email account is configured for the landlord user (User ID: 2) and receives email notifications for various rent-related events.

### When Notifications Are Sent

Email notifications are automatically sent in the following scenarios:

1. **Pending** - When a user creates a new rent request
   - **Recipient:** Landlord
   - **Subject:** "New Rent Request - [Property Title]"

2. **Cancelled** - When a user cancels a rent request (from Pending or Accepted status)
   - **Recipient:** Landlord
   - **Subject:** "Rent Cancelled - [Property Title]"

3. **Accepted** - When a landlord accepts a rent request
   - **Recipient:** User (tenant)
   - **Subject:** "Rent Request Accepted - [Property Title]"

4. **Rejected** - When a landlord rejects a rent request
   - **Recipient:** User (tenant)
   - **Subject:** "Rent Request Rejected - [Property Title]"

5. **Paid** - When a user completes payment for an accepted rent
   - **Recipient:** Landlord
   - **Subject:** "Payment Received - [Property Title]"

### Notification System Architecture

The notification system uses:
- **RabbitMQ** for message queuing
- **eRent.Subscriber** service that listens for rent notifications
- **Gmail SMTP** for sending HTML email notifications
- Asynchronous processing to avoid blocking rent operations

## 🏗️ Project Structure

```
eRent/
├── eRent.WebAPI/              # .NET Core Web API (Backend)
│   ├── Controllers/           # API Controllers
│   ├── Filters/               # Exception and Authentication filters
│   ├── Assets/                 # Property images and user pictures
│   └── Program.cs             # Application entry point
│
├── eRent.Services/             # Business Logic Layer
│   ├── Database/               # Entity Framework models and DbContext
│   │   ├── DataSeeder.cs      # Database seeding with test data
│   │   └── eRentDbContext.cs  # Database context
│   ├── Services/              # Service implementations
│   ├── Interfaces/             # Service interfaces
│   └── Helpers/                # Utility classes
│
├── eRent.Model/                # Data Transfer Objects (DTOs)
│   ├── Requests/               # Request models
│   ├── Responses/              # Response models
│   └── SearchObjects/          # Search/filter models
│
├── eRent.Subscriber/           # Email Notification Service
│   ├── Services/               # Email sender and template services
│   └── Models/                 # Notification models
│
└── UI/                         # Flutter Applications
    ├── erent_desktop/          # Admin desktop app
    ├── erent_landlord_desktop/ # Landlord desktop app
    └── erent_mobile/           # Mobile app
```

## 🛠️ Technology Stack

### Backend
- **.NET Core** - Web API framework
- **Entity Framework Core** - ORM for database operations
- **SQL Server** - Database
- **RabbitMQ** - Message queue for notifications
- **Mapster** - Object mapping
- **Swagger** - API documentation

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language

### Infrastructure
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration

## 🗄️ Database

The system uses SQL Server with Entity Framework Core. The database is automatically seeded with:
- Test users (admin, landlords, regular users)
- Property types and amenities
- Sample properties with images
- Countries and cities (Balkan region)
- Sample rent records and reviews

## 🚀 Getting Started

### Prerequisites
- .NET SDK
- Flutter SDK
- Docker and Docker Compose
- SQL Server (or use Docker container)

### Running with Docker

1. Configure environment variables in `.env` file or `docker-compose.yml`
2. Run: `docker-compose up`

### Running Locally

1. Start SQL Server and RabbitMQ
2. Update connection strings in `appsettings.json`
3. Run the WebAPI project
4. Run the Subscriber service for email notifications
5. Run Flutter apps from their respective directories

## 📝 Features

- Property management (CRUD operations)
- User authentication and authorization
- Rent request management
- Payment processing
- Email notifications
- Property search and filtering
- Reviews and ratings
- Analytics for landlords and admins
- Chat functionality
- Image upload and management

## 🔒 Security

- Basic Authentication for API access
- Password hashing with salt
- Role-based access control (Administrator, User, Landlord)
- Input validation and exception handling

## 📄 License

See LICENSE file for details.
