allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")

    // google_navigation_flutter hardcodes compileSdk 35 (still true as of its latest
    // release, 0.11.0), but its own flutter_plugin_android_lifecycle dependency now
    // requires compileSdk 36+. AGP 9's AAR metadata check makes that a hard build
    // failure, so bump this one plugin's compileSdk to match the app's.
    if (project.name == "google_navigation_flutter") {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.compileSdk = 36
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
