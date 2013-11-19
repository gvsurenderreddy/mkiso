#!/usr/bin/env bash

create_md() {
	if [ ! -f ${tmpdir}/${mfsroot} ]; then 
		dd if=/dev/zero of=${tmpdir}/${mfsroot} bs=1024k count="${md_size}"
	fi
}

mount_md() {
	if [ -e /dev/md${md_number} ]; then
		umount_md
		mdconfig -d -u ${md_number}
	fi

  mdconfig -a -t vnode -f ${tmpdir}/${mfsroot} -u ${md_number}

	newfs  /dev/md${md_number}

	mount /dev/md${md_number} ${absd_mount}
}

populate_temproot() {
	if [ ! -d ${temp_mount}/var/lib/pacman ]; then
		install -dm755 ${temp_mount}/var/lib/pacman
	fi

	pacman -Sydd --noconfirm freebsd-world -r ${temp_mount}
}

populate_absd_mount() {
	for dir in bin  dev  etc  lib  libexec  \
		media  mnt  proc  rescue  root  \
		sbin  sys  tmp  usr  var rw_etc rw_var; do
		install -dm755 ${absd_mount}/${dir}
	done

	install -m644 ${files}/pacman.conf.clean ${absd_mount}/etc/pacman.conf

	for dirs in usr/bin usr/sbin usr/libexec usr/share usr/lib; do
		install -dm755 ${absd_mount}/${dirs}
	done

	install -dm755 ${absd_mount}/var/{lib,cache}/pacman

	while read file; do
		cp -a ${temp_mount}/${file} ${absd_mount}/${file}
	done < ${files}/filelist

	while read libfile; do
		cp -Ra ${temp_mount}/${libfile} ${absd_mount}/usr/lib/
	done < ${files}/liblist

	while read dir; do
		cp -a ${temp_mount}/${dir} ${absd_mount}/${dir}
	done < ${files}/dirlist

	for cdirs in bin sbin libexec lib; do
		cp -a ${temp_mount}/${cdirs} ${absd_mount}/
	done
}

install_packages() {
	pac_list=(archbsd-keyring  bash  ca_root_nss  curl  cyrus-sasl  freetype2  fusefs-libs  gettext  gnupg  gpgme  libassuan
		libgcrypt  libgpg-error  libksba  libldap  libsasl  openrc  pacman-mirrorlist  pinentry  pth  grub-bios grub-common  pacman)

	pacman -Sydd --noconfirm ${pac_list[@]} -r ${absd_mount}/ --force
}

umount_md() {
	umount -f /dev/md${md_number}
}

compress_mfsroot() {
	gzip -9 ${tmpdir}/${mfsroot}	
}

create_structure() {
	install -dm755 ${absd_dir}/var/lib/pacman

	pacman -Sy freebsd-kernel -r ${absd_dir}

	if [ -z ${absd_dir} ] && [ -d ${absd_dir}/var ]; then
		rm -rf ${absd_dir}/var
	fi

	install -dm755 ${mfsroot} ${absd_dir}
}


