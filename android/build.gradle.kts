buildscript {
    val kotlinVersion = "2.1.10" // Update this to the latest version

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        // NOTE: Do not place your application dependencies here; they belong
        // in the individual module build.gradle.kts files
    }
}

plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}



rootProject.buildDir = File(rootProject.projectDir, "../build")

subprojects {
    buildDir = File(rootProject.buildDir, name)
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
