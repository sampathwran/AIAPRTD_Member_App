// 1. Plugins Block එක (අලුත් ක්‍රමය)
plugins {
    // 8.2.1 වෙනුවට 8.2.2 හෝ 9.2.1 (9.2.1 අලුත්ම නිසා අපි ඒකටම යමු)
    id("com.android.application") version "9.2.1" apply false
    // 1.9.0 වෙනුවට 2.4.0
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    // 4.4.1 වෙනුවට 4.4.4
    id("com.google.gms.google-services") version "4.4.4" apply false
}

// 2. Repositories
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 3. Build Directory Configuration
rootProject.layout.buildDirectory.value(layout.buildDirectory.dir("../../build"))

subprojects {
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir(project.name))
}

// 4. Clean Task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}