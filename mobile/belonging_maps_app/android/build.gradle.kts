import com.android.build.gradle.LibraryExtension

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

// Older Android plugins still declare their namespace in the manifest.
subprojects {
    plugins.withId("com.android.library") {
        val manifest = project.file("src/main/AndroidManifest.xml")
        if (manifest.isFile) {
            val manifestNamespace = Regex("""package\s*=\s*["']([^"']+)["']""")
                .find(manifest.readText())
                ?.groupValues
                ?.get(1)
            val androidExtension = project.extensions.findByType<LibraryExtension>()
            if (androidExtension != null && androidExtension.namespace.isNullOrBlank()
                && !manifestNamespace.isNullOrBlank()) {
                androidExtension.namespace = manifestNamespace
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
