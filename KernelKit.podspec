Pod::Spec.new do |s|
    s.name         = "KernelKit"
    s.version      = "1.0.0"
    s.summary      = "utilities"
    s.homepage     = 'https://github.com/jasenhuang/KernelKit'
    s.license      = { :type => 'MIT' }
    s.author       = { 'jasenhuang' => 'jasenhuang@rdgz.org' }
    s.source       = { :git => "https://github.com/jasenhuang/KernelKit.git" }

    s.source_files  = "KernelKit/*.{h,m,mm,S,c}",
    s.public_header_files = "KernelKit/Crash/*.h",
                            "KernelKit/DYLD/*.h",
                            "KernelKit/Hook/*.h",
                            "KernelKit/IO/*.h",
                            "KernelKit/Memory/*.h",
                            "KernelKit/ObjC/*.h",
                            "KernelKit/Thread/*.h",
                            "KernelKit/Utils/*.h",
                            "KernelKit/KernelKit.h"
    s.compiler_flags = '-x objective-c++'
    s.requires_arc = true
    s.frameworks   = "Foundation"
    s.libraries    = 'c++', 'z'
    s.pod_target_xcconfig = {
        "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++17",
        "CLANG_CXX_LIBRARY" => "libc++",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF" => "NO",
    }
end