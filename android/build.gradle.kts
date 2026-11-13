import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

// pdf_text 0.5.0 requests the original JCenter-only coordinate
// com.tom_roush:pdfbox-android:1.8.10.1. JCenter is no longer a
// reliable source, so redirect that legacy request to the compatible
// 1.8.10.3 artifact published on Maven Central under the corrected group.
subprojects {
    configurations.configureEach {
        resolutionStrategy.dependencySubstitution {
            substitute(module("com.tom_roush:pdfbox-android"))
                .using(module("com.tom-roush:pdfbox-android:1.8.10.3"))
        }
    }
}

// pdf_text 0.5.0 predates Android Gradle Plugin 8 and does not declare
// an Android namespace. Derive it from the plugin's own manifest instead
// of hard-coding a third-party package name or modifying the pub cache.
subprojects {
    if (name == "pdf_text") {
        // pdf_text's Java sources compile to JVM 1.8 while Kotlin 2.2
        // defaults to JVM 17. Keep both outputs on the library's Java target.
        tasks.withType<KotlinCompile>().configureEach {
            kotlinOptions.jvmTarget = "1.8"
        }

        val manifestFile = file("src/main/AndroidManifest.xml")
        val manifestPackage = if (manifestFile.isFile) {
            Regex("""package\s*=\s*["']([^"']+)["']""")
                .find(manifestFile.readText())
                ?.groupValues
                ?.get(1)
        } else {
            null
        }

        plugins.withId("com.android.library") {
            val androidExtension = extensions.findByName("android")
                ?: error("Android extension was not created for pdf_text")

            val namespaceGetter = androidExtension.javaClass.methods
                .firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
                ?: error("Cannot read Android namespace for pdf_text")

            val currentNamespace = namespaceGetter.invoke(androidExtension) as? String
            if (currentNamespace.isNullOrBlank()) {
                val namespace = manifestPackage
                    ?: error("pdf_text manifest does not declare a package; cannot infer namespace")

                val namespaceSetter = androidExtension.javaClass.methods
                    .firstOrNull {
                        it.name == "setNamespace" &&
                            it.parameterCount == 1 &&
                            it.parameterTypes[0] == String::class.java
                    }
                    ?: error("Cannot set Android namespace for pdf_text")

                namespaceSetter.invoke(androidExtension, namespace)
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
