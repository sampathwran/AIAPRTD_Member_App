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
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {

            try {
                val setCompileSdkMethod = androidExt.javaClass.getMethod("setCompileSdk", Int::class.java)
                setCompileSdkMethod.invoke(androidExt, 36)
            } catch (_: Exception) { // 💡 'e' වෙනුවට '_' දැම්මා (Warning එක නැති කරන්න)
                try {
                    val compileSdkVersionMethod = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.java)
                    compileSdkVersionMethod.invoke(androidExt, 36)
                } catch (_: Exception) { // 💡 'e2' වෙනුවට '_' දැම්මා
                    // Ignore
                }
            }

            // Fix Namespace
            try {
                val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                val namespaceProp = getNamespace.invoke(androidExt)
                if (namespaceProp == null) {
                    val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(androidExt, project.group.toString())
                }
            } catch (_: Exception) { // 💡 'e' වෙනුවට '_' දැම්මා
                // Ignore
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