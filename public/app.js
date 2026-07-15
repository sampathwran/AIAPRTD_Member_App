// Firebase Configuration
const firebaseConfig = {
    apiKey: "AIzaSyCDBGrVPwHFh3gNs_AXY7o1lFfsBw_1B00",
    appId: "1:1012060339384:web:2d4cceffb2f8ed8dcac84d",
    messagingSenderId: "1012060339384",
    projectId: "aiaprtd-member",
    authDomain: "aiaprtd-member.firebaseapp.com",
    storageBucket: "aiaprtd-member.firebasestorage.app",
    measurementId: "G-YZ9MZ3LF8R"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// DOM Elements
const loader = document.getElementById('loader');
const errorBox = document.getElementById('error-box');
const errorText = document.getElementById('error-text');
const mainContent = document.getElementById('main-content');

const tripStatus = document.getElementById('trip-status');
const pickupLoc = document.getElementById('pickup-location');
const dropLoc = document.getElementById('drop-location');
const vehicleDetails = document.getElementById('vehicle-details');
const driverName = document.getElementById('driver-name');
const driverImg = document.getElementById('driver-img');
const vehicleImg = document.getElementById('vehicle-img');
const vehiclePlaceholder = document.getElementById('vehicle-placeholder');

// Get Trip ID from URL
const urlParams = new URLSearchParams(window.location.search);
const tripId = urlParams.get('id');

if (!tripId) {
    showError("Invalid tracking link. Trip ID is missing.");
} else {
    listenToTrip(tripId);
}

function showError(msg) {
    loader.style.display = 'none';
    mainContent.style.display = 'none';
    errorBox.style.display = 'block';
    errorText.textContent = msg;
}

function updateStatus(state) {
    let text = "Pending";
    let color = "#3b82f6"; // blue
    let bg = "rgba(59, 130, 246, 0.2)";

    if (state === 'accepted') {
        text = "Driver on the way";
    } else if (state === 'arrived') {
        text = "Driver Arrived";
        color = "#f59e0b"; // amber
        bg = "rgba(245, 158, 11, 0.2)";
    } else if (state === 'started') {
        text = "Trip in Progress";
        color = "#10b981"; // green
        bg = "rgba(16, 185, 129, 0.2)";
    } else if (state === 'completed') {
        text = "Completed";
        color = "#10b981";
        bg = "rgba(16, 185, 129, 0.2)";
    } else if (state === 'cancelled') {
        text = "Cancelled";
        color = "#ef4444"; // red
        bg = "rgba(239, 68, 68, 0.2)";
    }

    tripStatus.textContent = text;
    tripStatus.style.color = color;
    tripStatus.style.backgroundColor = bg;
}

let fetchedVehicleImage = false;

function listenToTrip(id) {
    db.collection('all_bookings').doc(id).onSnapshot((doc) => {
        if (!doc.exists) {
            showError("We couldn't find this trip. It might have been deleted.");
            return;
        }

        const data = doc.data();

        // Update UI
        loader.style.display = 'none';
        errorBox.style.display = 'none';
        mainContent.style.display = 'block';

        const pLoc = data.pickupLocation?.address || data.startAddress || 'Unknown Pickup';
        const dLoc = data.dropLocation?.address || data.endAddress || 'Unknown Drop-off';
        
        pickupLoc.textContent = pLoc;
        dropLoc.textContent = dLoc;
        vehicleDetails.textContent = data.driverVehicle || data.vehicleCategory || data.vehicle?.name || 'Vehicle';
        
        if (data.driverName) driverName.textContent = data.driverName;
        if (data.driverImage) driverImg.src = data.driverImage;
        
        updateStatus(data.tripState || data.status?.toLowerCase() || 'accepted');

        // Fetch vehicle image if not done yet
        if (!fetchedVehicleImage && data.acceptedBy) {
            fetchVehicleImage(data.acceptedBy);
            fetchedVehicleImage = true;
        }

    }, (error) => {
        console.error("Error fetching trip:", error);
        showError("Failed to fetch trip details. Please try again.");
    });
}

function fetchVehicleImage(driverId) {
    db.collection('vehicles').doc(driverId).get().then(doc => {
        if (doc.exists) {
            const data = doc.data();
            const frontImage = data.vehiclePhotos?.front?.url;
            
            if (frontImage) {
                vehiclePlaceholder.style.display = 'none';
                vehicleImg.src = frontImage;
                vehicleImg.style.display = 'block';
            }
        }
    }).catch(err => {
        console.log("Could not load vehicle image:", err);
    });
}
