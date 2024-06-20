<p align="center">
  <img src="images/logo.png" width="200" title="BUET LOGO">
</p>

# ByteWise : A Quality of Life IOT App For ESP32
### Developed By: Jayden Roelofs | Chris Lamus
### Department : Computer Science and Engineering
---
## 1 Abstract

When working with microcontrollers, development and programming can be tedious and time consuming for the unexperienced user, especially if they have not had any previous exposure. Whether it's a passion project or someone simply wants to experiement, the complexity that can come with microcontrollers could be discouraging to the average user. The **ByteWise** app aims to simplify the development process by providing a user friendly interface to connect an ESP-32 and begin development right away.

## 2 Introduction

**ByteWise** is an Android mobile application enabling fast development for the ESP-32. The user is required to create an account to use the service in order to remember user setting and configurations for their board. Once a board is connected, the **ByteWise** app provides the user with I/O pin on the board accompanied by a select pin functionality. This allows the user to customize their board to their liking and functionality with the simple interface of the **ByteWise** app.
## 3 Architectural Design

The **ByteWise** app communicates with the ESP-32 using a wifi connection. Once the app and the ESP-32 are on a wifi network, they communicate using MQTT messaging to send and recieve updates. The app sends commands for pin functionality and the esp will repond back with updates to the user to reflect the desired function. Users will create an account to use the app and the account info and associated settings for the individuals board will be stored within a *to be determined* database. 

### 3.1 Class Diagram

### 3.2 Sequence Diagram

## 4 User Guide/Implementation

### 4.1 Client Side

#### 4.1.1 Starting the Application

#### 4.1.2 Registration

#### 4.1.3 LogIn

### 4.2 Home

#### 4.2.1 Vehicle Details

#### 4.2.2 Adding Garage as Renter

#### 4.2.3 Location Selection for Parking

#### 4.2.4 Notification Details

### 4.3 Confirmation and Payment

### 4.4 Server Side

## 5 Future Scope

## 6 Conclusion

## 7 Walkthrough
