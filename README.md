# Restaurant Recommendation System

## Objective:

This project aims to develop an intelligent restaurant recommendation system that streamlines the process of discovering and trying new restaurants in a specified area. Users will create an account and input their preferred cuisine type and location (city, county, etc.). Our system will leverage Google Geocoding API to obtain geo-coordinates for the specified area and Google’s Places API to retrieve a list of relevant restaurants. A recommendation engine will then cross-reference these restaurants with an internal database to determine if other users have previously visited and recommended them. If prior recommendations exist, the system will suggest the most highly rated option; otherwise, it will default to Google’s highest-rated restaurant.

To enhance user engagement, the system will send an email or text prompting users to submit a simple recommendation (approve/disapprove), which will be processed to update our internal database. The architecture consists of five core microservices handling (1) user management, (2) geo-localization, (3) restaurant lookup, (4) recommendation engine, and (5) notification service.

Future extensions could incorporate machine learning to suggest restaurants beyond the initial radius based on user preferences, introduce alternative cuisine recommendations, or automate reservations through AI-driven phone calls. This minimal-input, interaction-free system ensures a seamless user experience while maintaining a robust and scalable recommendation pipeline.


## System Diagram:
<img width="561" alt="Screenshot 2025-05-06 at 12 04 22" src="https://github.com/user-attachments/assets/71a572d3-3719-4226-817e-6045e9adec88" />

## Core Microservices:
1.	User Management:
  	-	User sign-up and login
  	-	Creating/updating user preferences (eg. preferred cuisine type and location)
  	-	Processing user feedback
2.	Geo-Localization:
  	-	Fetching X-Y coordinates from Google Geocoding API given an address
3.	Restaurant Lookup:
  	-	Fetching list of restaurants from Google’s Places API given X-Y coordinates
4.	Recommendation Engine:
  	-	Apply a user-based collaborative filtering algorithm (a type of recommender system) to:
    	1.	Filter users who share the same preferences with active user
    	2.	Use ratings from like-minded users found in step 1 to calculate prediction for active user
5.	Notification Service:
  	-	Prompts user to submit a restaurant rating


## Tech Stack:
-	FastAPI for backend
-	React + Next.js + TailwindCSS for frontend
-	AWS RDS for SQL database
-	AWS EC2 for VM instances + load balancers
-	AWS Amplify for hosting frontend
-	AWS SQS for message queuing
-	AWS API Gateway for API management + routing
-	AWS ECS for container orchestration
-	AWS ECR for image repository
-	Docker for containers
-	GitHub Actions for CI/CD pipeline


## Outcome:

The restaurant recommendation system will provide users with a seamless, automated way to discover highly-rated restaurants tailored to their preferences. By leveraging geo-coordinates, Google Places data, and user-driven recommendations, the system will deliver personalized dining suggestions with minimal user interaction. Key outcomes include:
	-	Effortless Restaurant Discovery: Users receive curated restaurant recommendations based on cuisine and location preferences without needing to search manually.
	-	Community-Driven Recommendations: The system improves over time as more users provide feedback, refining recommendations for future users.
	-	Automated and Scalable Architecture: The microservices-based design ensures modularity, making it easy to expand functionalities such as ML-powered recommendations, reservation handling, or chatbot integration.
	-	Improved User Experience: A streamlined process requiring only a cuisine and location input, reducing friction in the decision-making process.
