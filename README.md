# LibreSpace Data Warehouse / Entrepôt de données LibreSpace

---

## 🇬🇧 English

### Project Overview

This project implements a complete **Data Warehouse (DW)** solution for **LibreSpace**, a bookstore management system. The solution uses **SQL Server** and follows dimensional modeling principles to enable business intelligence and analytics on book orders, inventory, suppliers, and sales data.

### Features

- **Dimensional Data Warehouse Design**: Implements a star schema with fact and dimension tables
- **Incremental ETL Process**: Automated Extract, Transform, Load processes with change tracking
- **Slowly Changing Dimensions (SCD)**: Type 2 SCD implementation for tracking historical changes
- **Date Dimension**: Calendar dimension with recursive population
- **Trigger-based Change Detection**: Database triggers to track modifications in source tables
- **Staging Views**: Intermediate views for data transformation before loading into the data warehouse

### Architecture

#### Source Database: `LibreSpaceTransacDB`
Transactional database containing operational data for:
- Books (Livre)
- Suppliers (Fournisseur)
- Orders (CommandeFournisseur, CommandeLivre)
- Authors (Auteur, AuteurLivre)
- Publishers (Editeur)
- Inventory (QuantiteStock)
- Genres (Genre)

#### Data Warehouse: `LibreSpaceDW`

**Dimension Tables:**
- `DIM_DATE`: Date dimension with calendar attributes
- `DIM_FOURNISSEUR`: Supplier dimension
- `DIM_LIVRE`: Book dimension with SCD Type 2 implementation

**Fact Table:**
- `Fait_CommandeLivre`: Book order facts including quantities, costs, margins, and order status

**Control Table:**
- `LibreSpaceDW_ETLConfig`: Tracks last modification dates for incremental loading

### ETL Process

1. **Change Detection**: Triggers on source tables update `DateModification` timestamp
2. **Staging**: Views filter changed records since last ETL run
3. **Loading**: MERGE statements handle INSERT and UPDATE operations
4. **Tracking**: ETL config table updated with current timestamp

### Usage

#### Prerequisites
- Microsoft SQL Server (2016 or later recommended)
- Access to both source database (`LibreSpaceTransacDB`) and data warehouse
- Appropriate permissions to create databases, tables, views, and triggers

#### Installation

1. Ensure the source database `LibreSpaceTransacDB` exists and is populated
2. Execute the SQL script `Travail_individuel3_corrige.sql`
3. The script will:
   - Create the data warehouse `LibreSpaceDW`
   - Build all dimension and fact tables
   - Add triggers to source tables
   - Perform initial data load
   - Create staging views for future incremental loads

#### Running Incremental Loads

Simply re-execute the relevant sections of the script. The ETL process automatically:
- Detects changes since last run
- Updates existing records
- Inserts new records
- Maintains historical data (for SCD Type 2 dimensions)

### Sample Queries

The script includes analytical queries such as:
- Books with multiple authors
- Top 3 suppliers by order volume for specific genres
- Best performing supplier per genre
- Supplier performance analysis

### 📁 Repository Contents

- `Travail_individuel3_corrige.sql`: Complete SQL implementation
- `Travail individuel no. 3 - Énoncé.pdf`: Project requirements document (French)

### Technical Highlights

- **Recursive CTEs** for date dimension population
- **MERGE statements** for efficient upsert operations
- **Triggers** for automatic change tracking
- **Type 2 SCD** with effective dates and status flags
- **Staging views** for transformation logic
- **Incremental loading** to minimize processing overhead

---

## 🇫🇷 Français

### Aperçu du projet

Ce projet implémente une solution complète d'**entrepôt de données (ED)** pour **LibreSpace**, un système de gestion de librairie. La solution utilise **SQL Server** et suit les principes de modélisation dimensionnelle pour permettre l'intelligence d'affaires et l'analyse des commandes de livres, de l'inventaire, des fournisseurs et des données de ventes.

### Fonctionnalités

- **Conception d'entrepôt de données dimensionnel**: Implémente un schéma en étoile avec tables de faits et de dimensions
- **Processus ETL incrémental**: Processus automatisés d'extraction, transformation et chargement avec suivi des changements
- **Dimensions à variation lente (SCD)**: Implémentation SCD de Type 2 pour suivre les changements historiques
- **Dimension Date**: Dimension calendaire avec population récursive
- **Détection des changements par déclencheurs**: Triggers de base de données pour suivre les modifications dans les tables sources
- **Vues de staging**: Vues intermédiaires pour la transformation des données avant chargement

### Architecture

#### Base de données source : `LibreSpaceTransacDB`
Base de données transactionnelle contenant les données opérationnelles pour :
- Livres (Livre)
- Fournisseurs (Fournisseur)
- Commandes (CommandeFournisseur, CommandeLivre)
- Auteurs (Auteur, AuteurLivre)
- Éditeurs (Editeur)
- Inventaire (QuantiteStock)
- Genres (Genre)

#### Entrepôt de données : `LibreSpaceDW`

**Tables de dimension :**
- `DIM_DATE`: Dimension de date avec attributs calendaires
- `DIM_FOURNISSEUR`: Dimension fournisseur
- `DIM_LIVRE`: Dimension livre avec implémentation SCD Type 2

**Table de faits :**
- `Fait_CommandeLivre`: Faits de commande de livres incluant quantités, coûts, marges et statut de commande

**Table de contrôle :**
- `LibreSpaceDW_ETLConfig`: Suit les dates de dernière modification pour le chargement incrémental

### Processus ETL

1. **Détection des changements**: Les triggers sur les tables sources mettent à jour l'horodatage `DateModification`
2. **Staging**: Les vues filtrent les enregistrements modifiés depuis la dernière exécution ETL
3. **Chargement**: Les instructions MERGE gèrent les opérations INSERT et UPDATE
4. **Suivi**: La table de configuration ETL est mise à jour avec l'horodatage actuel

### Utilisation

#### Prérequis
- Microsoft SQL Server (version 2016 ou ultérieure recommandée)
- Accès à la base de données source (`LibreSpaceTransacDB`) et à l'entrepôt de données
- Permissions appropriées pour créer des bases de données, tables, vues et triggers

#### Installation

1. Assurez-vous que la base de données source `LibreSpaceTransacDB` existe et est peuplée
2. Exécutez le script SQL `Travail_individuel3_corrige.sql`
3. Le script va :
   - Créer l'entrepôt de données `LibreSpaceDW`
   - Construire toutes les tables de dimensions et de faits
   - Ajouter des triggers aux tables sources
   - Effectuer le chargement initial des données
   - Créer des vues de staging pour les futurs chargements incrémentaux

#### Exécution des chargements incrémentaux

Simplement ré-exécuter les sections pertinentes du script. Le processus ETL automatiquement :
- Détecte les changements depuis la dernière exécution
- Met à jour les enregistrements existants
- Insère les nouveaux enregistrements
- Maintient les données historiques (pour les dimensions SCD Type 2)

### Requêtes d'exemple

Le script inclut des requêtes analytiques telles que :
- Livres avec plusieurs auteurs
- Top 3 des fournisseurs par volume de commandes pour des genres spécifiques
- Meilleur fournisseur par genre
- Analyse de performance des fournisseurs

### 📁 Contenu du dépôt

- `Travail_individuel3_corrige.sql`: Implémentation SQL complète
- `Travail individuel no. 3 - Énoncé.pdf`: Document des exigences du projet (français)

### Points techniques saillants

- **CTEs récursifs** pour la population de la dimension date
- **Instructions MERGE** pour des opérations upsert efficaces
- **Triggers** pour le suivi automatique des changements
- **SCD Type 2** avec dates effectives et indicateurs de statut
- **Vues de staging** pour la logique de transformation
- **Chargement incrémental** pour minimiser la charge de traitement

---

## License

This project is part of academic coursework.

Ce projet fait partie d'un travail académique.

---

## 👤 Author / Auteur

Julia11614
