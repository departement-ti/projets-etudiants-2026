# SmartTenant

<p align="center">
  <strong>SmartTenant</strong>
</p>

<p align="center">
  A modern rental and property management platform designed to simplify property operations, tenant management, billing, maintenance tracking, and financial reporting.
</p>

<p align="center">
  <em>Final Year Project — PFE 2026</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Frontend-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Backend-NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" />
  <img src="https://img.shields.io/badge/Database-PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/ORM-Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white" />
  <img src="https://img.shields.io/badge/Auth-JWT-black?style=for-the-badge&logo=jsonwebtokens&logoColor=white" />
</p>

---

## Table of Contents

- [Overview](#overview)
- [Project Objectives](#project-objectives)
- [Features](#features)
- [User Roles](#user-roles)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Backend Setup](#backend-setup)
- [Frontend Setup](#frontend-setup)
- [Environment Variables](#environment-variables)
- [Demo Accounts](#demo-accounts)
- [Screenshots](#screenshots)
- [Academic Context](#academic-context)
- [Author](#author)

---

## Overview

**SmartTenant** is a rental and property management application developed to help property owners, administrators, assistants, maintenance agents, and tenants manage rental operations from a centralized digital platform.

The application provides tools for managing properties, units, tenants, leases, invoices, payments, maintenance tickets, notifications, audit logs, financial reports, and intelligent assistance features.

SmartTenant is built using a client-server architecture with a **Flutter frontend**, a **NestJS REST API backend**, and a **PostgreSQL database** managed through **Prisma ORM**.

---

## Project Objectives

The main objectives of SmartTenant are:

- Centralize rental and property management data.
- Reduce manual administrative work.
- Improve invoice and payment tracking.
- Simplify lease and tenant management.
- Provide maintenance ticket tracking.
- Improve communication between tenants and management.
- Secure access using authentication and role-based permissions.
- Generate financial reports for better decision-making.

---

## Features

### Authentication and Authorization

- Secure login system
- JWT-based authentication
- Password hashing using bcrypt
- Role-based access control
- Protected backend routes

### Organization and User Management

- Manage organizations
- Manage users
- Assign roles and permissions
- Separate access depending on user responsibility

### Property and Unit Management

- Create and manage properties
- Create and manage rental units
- Track unit availability and status
- Associate units with properties

### Tenant Management

- Register and manage tenants
- View tenant information
- Link tenants to leases and units

### Lease Management

- Create rental leases
- Associate tenants with units
- Manage lease dates and rent amount
- Generate initial and recurring invoices

### Invoice and Payment Management

- Generate invoices
- Track invoice status
- Register payments
- Support partial payments
- Calculate remaining payment amounts

### Maintenance Ticket Management

- Tenants can create maintenance requests
- Agents can manage and update tickets
- Ticket assignment
- Ticket messages and conversation history
- Ticket status tracking

### Notifications and Audit Logs

- Notify users about important actions
- Track important system activities
- Store audit logs for traceability

### Dashboard and Reports

- Dashboard statistics
- Financial reporting
- PDF report generation
- Overview of payments, invoices, and rental activity

### Intelligent Assistance

- Tenant analysis
- Tenant risk score
- Suggested replies for maintenance tickets
- Assistant-oriented dashboard features

---

## User Roles

SmartTenant supports multiple user roles:

| Role | Description |
|---|---|
| Administrator | Manages the overall system, organizations, users, and global data |
| Owner | Manages properties, units, leases, invoices, payments, and reports |
| Administrative Assistant | Helps manage tenants, leases, invoices, and daily administrative operations |
| Maintenance Agent | Handles maintenance tickets and ticket updates |
| Tenant | Views personal data, invoices, payments, and submits maintenance requests |

---

## Tech Stack

### Frontend

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform frontend development |
| Dart | Programming language for Flutter |
| HTTP Client | API communication with the backend |
| Secure Storage | Local authentication token storage |

### Backend

| Technology | Purpose |
|---|---|
| NestJS | Backend framework |
| TypeScript | Backend programming language |
| Prisma ORM | Database access and schema management |
| PostgreSQL | Relational database |
| JWT | Authentication |
| Bcrypt | Password hashing |

### Development Tools

| Tool | Purpose |
|---|---|
| Git / GitHub | Version control and project hosting |
| VS Code | Code editor |
| Postman | API testing |
| Prisma Studio | Database visualization |
| Android Studio / Chrome | Application testing |

---

## Project Structure

```text
PFE_2026_SmartTenant/
├── backend/                 # NestJS backend API
│   ├── prisma/              # Prisma schema and seed data
│   └── src/                 # Backend source code
│
├── frontend/                # Flutter frontend application
│   ├── lib/                 # Flutter source code
│   ├── android/             # Android platform files
│   ├── ios/                 # iOS platform files
│   ├── web/                 # Web platform files
│   └── pubspec.yaml         # Flutter dependencies
│
├── README.md
└── .gitignore
