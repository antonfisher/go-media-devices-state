fn main() {
    #[cfg(target_os = "macos")]
    macos_build();
}

#[inline]
fn macos_build() {
    let dst = cmake::build("libmediastate");

    println!("cargo:rustc-link-search=native={}/lib", dst.display());
    println!("cargo:rustc-link-lib=static=mediastate");
}
