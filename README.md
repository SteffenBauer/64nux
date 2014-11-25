64nux
====================
![64nux](https://raw.githubusercontent.com/SteffenBauer/64nux/master/64nux.png)

A small Unix-like operation system for the C64.

Original project to be found at: [LUnix](http://lng.sourceforge.net/)
See also [64-lng](https://github.com/ytmytm/c64-lng)

My modifications so far:
 * C64-only
 * Some cleanup of the kernel source code organization
 * Moved screen memory to the C000-FFFF block.
 * Now using memory below D000-D800 as customized character memory. Modified the character map to be more compliant with VT100.
 * New tool **memmap** to show current memory usage (per memory page)
 * New tool **charmap** to show character map (shifted/unshifted and inverse characters)
 
Work in progress:
 * **ed** text editor
 
### License

Licensed under the GNU Lesser General Public License 2.0, see LICENSE

Original copyright Daniel Dallmann.and the LNG community

