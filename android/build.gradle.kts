allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. flutter_timezone 3.0.1) ship their own Android module with a Java/Kotlin
// target mismatch (javac 11 vs Kotlin 1.8), which AGP now rejects outright. Force every
// subproject onto the same JVM target as the app module (see android/app/build.gradle.kts)
// so those plugins build instead of failing with "Inconsistent JVM Target Compatibility".
subprojects {
    // :app already sets its own Java 17 / Kotlin JVM_17 target explicitly (see
    // android/app/build.gradle.kts) and finalizes it during its own evaluation - reconfiguring
    // it here throws "sourceCompatibility has been finalized". Plugin library modules use
    // `plugins.withId`, which fires as soon as the plugin is applied rather than waiting for
    // full evaluation, so it doesn't race AGP's own finalization the way afterEvaluate did.
    if (project.path == ":app") return@subprojects
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
