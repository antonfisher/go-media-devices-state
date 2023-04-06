fn main() {
    let dst = cmake::build("libmediastate");

    println!("cargo:rustc-link-search=native={}/lib", dst.display());
    println!("cargo:rustc-link-lib=static=mediastate");
}
