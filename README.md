# Team Name

LYRE

# Proposed Level of Achievement

Apollo

# Motivation

Being huge fans of music, we were drawn to the idea of building a mood to music journal, a space where emotional reflection and music naturally intersect. More than just a journaling tool, we saw it as a way to help users recognize their emotional patterns over time, while making the experience feel intimate and genuinely enjoyable.

At the same time, we noticed that many people struggle to maintain consistent journaling habits, often finding traditional journals too plain or disconnected from their daily lives. Music, on the other hand, is something most people engage with every single day. By bridging the two, we wanted to create something that felt less like a chore and more like a natural extension of how people already process their emotions. We believe a mood to music journal can make self-reflection more accessible and meaningful for a wide range of users.

# User Stories

1. As someone who links certain songs to certain moments, I want to add songs or artists to each entry so I can capture the music that matches my mood.
2. As someone who wants to look back on past emotions, I want to browse and filter my old entries by mood or date so I can revisit them easily.
3. As someone who wants to understand myself better, I want to write a journal entry with my mood and a short reflection so I can remember how I felt that day. I also want to see simple patterns in my moods and music choices so I can notice trends over time.

# Scope of Project

LYRE is a mobile application designed as a mood-to-music journal. We plan to use Flutter (Dart), Firebase, and the Spotify API as the core building blocks of the app, with Git & GitHub for version control.

To ensure that each user's journal entries and preferences remain private and accessible only to them, we have implemented an authentication system that requires users to sign in before using LYRE.

Users can navigate between different features of the app using the navigation bar. These features include journal entry creation, a history view, an insights dashboard, and more.

# Features

## Core: Authentication System
LYRE is designed to be used upon sign-in. We use Firebase Authentication as the identity provider and Firebase Firestore as the database for storing user data.

Current Progress: We have implemented the Login and Register screens with email and password authentication. Users are able to sign up, log in, and are routed to the main journal screen upon successful authentication.

## Core: Journal Entry Creation and Management
Users can write a reflection, select a mood from a predefined set of options, and attach a song or artist from Spotify to each entry, capturing exactly how they felt at the time of writing. Each entry is saved to Firestore and tied to the authenticated user's account.

Current Progress: We have implemented the journal entry creation screen. Users can write a text reflection, pick a mood, and save entries to Firestore. Spotify song attachment is planned for Milestone 2.

## Extension: Tagging System
Users can add custom tags like school, comfort, late_night to give each entry additional context beyond mood alone.

Current Progress: Not yet implemented. Planned for Milestone 2.

## Extension: Filters
Users can search and sort their entries by tag, mood, or date to find exactly what they are looking for across their journal history.

Current Progress: Not yet implemented. Planned for Milestone 2.

## Extension: Journal History
Users can browse all past entries in one place, ordered chronologically so that nothing is lost over time.

Current Progress: Not yet implemented. Planned for Milestone 2.

## Extension: Calendar View
Users can see their entries laid out on a monthly calendar grid, giving a visual overview of their journaling activity.

Current Progress: Not yet implemented. Planned for Milestone 2.

## Extension: Insights Dashboard
Users can discover patterns in their listening and emotional history: mood trends over time, top artists and songs, and most-used tags.

Current Progress: Not yet implemented. Planned for Milestone 3.

# Technology Stack

Flutter
Dart
Firebase Auth
Firebase Firestore
Git & Github
Spotify API

# Proposed Program Flow



# Development Plan

| Phase | Task | Description | Target Date |
|---|---|---|---|
| Preparation | Prepare Liftoff Poster and Video | Create Liftoff poster and slides, and record presentation pitch. | 15 May 2026 |
| Preparation | Pick Up Necessary Skills | Learn Flutter & Dart, Firebase Auth & Firestore, Git & GitHub. | 16 May 2026 |
| Preparation | Create App in Spotify API | Set up Spotify developer app and integrate API. | 17 May 2026 |
| Preparation | Prototype Creation | Build initial UI prototype. | ~24 May 2026 |
| Preparation | Implement Authentication Method | Set up login/register with Firebase Auth and integrate frontend with backend. | ~24 May 2026 |
| Milestone 1 | Ideation README & Proof of Concept | Complete initial project README and proof of concept. | 1 June 2026 |
| Development | Firestore Database Setup | Structure and connect Firestore to store journal entries per user; implement read and write operations. | ~8 June 2026 |
| Development | Journal Entry Creation and Management | Allow users to create, view, edit, and delete entries. Each entry includes date, mood, short reflection, and an attached song or artist from Spotify. | ~15 June 2026 |
| Development | Spotify API Integration | Implement in-app song and artist search using Spotify API, displaying track name, artist, and album art on entries. | ~22 June 2026 |
| Development | System Testing | Manually test core user flows: sign up, log in, create entry, edit entry, and delete entry. | ~29 June 2026 |
| Milestone 2 | First Working Prototype | Complete the first working prototype. | 29 June 2026 |
| Feature Expansion | Journal History and Filtering | Build a history view showing past entries chronologically; add filters by mood, date range, and keyword. | ~4 July 2026 |
| Feature Expansion | Insights Dashboard | Display patterns such as most frequent moods, most attached songs or artists, and entry frequency over time. | ~11 July 2026 |
| Feature Expansion | Tagging System | Allow users to add custom tags such as `school`, `comfort`, or `stress` to entries for richer organisation and filtering. | ~18 July 2026 |
| Feature Expansion | Calendar View | Show entries on a monthly calendar grid so users can see how their moods shifted across days and weeks. | ~25 July 2026 |
| Feature Expansion | User Testing and Documentation | Conduct user testing on completed features; update README with full feature descriptions, setup instructions, and design decisions. | ~27 July 2026 |
| Milestone 3 | Minimum Viable Product | Complete the MVP. | 27 July 2026 |
| Finalisation | Refinement and Polish | Fix bugs from user testing, improve UI consistency, and tighten edge cases across all features. | ~10 August 2026 |
| Finalisation | Splashdown: Refinement and Awarding | Final project refinement and presentation. | 26 August 2026 |

# Proof of Concept



# Project Log

Our project log is accessible through the following Google Sheets link:
https://docs.google.com/spreadsheets/d/1rLDhBnsf3d1k92-rT8nJCT8-4sXqbOeaQwM6hbZlJHc/edit?usp=sharing 
