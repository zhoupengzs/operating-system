
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 0a 31 00 00       	call   f0103167 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 36 10 f0       	push   $0xf0103600
f010006f:	e8 89 26 00 00       	call   f01026fd <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 d9 0f 00 00       	call   f0101052 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 97 06 00 00       	call   f010071d <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 1b 36 10 f0       	push   $0xf010361b
f01000b5:	e8 43 26 00 00       	call   f01026fd <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 13 26 00 00       	call   f01026d7 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 45 43 10 f0 	movl   $0xf0104345,(%esp)
f01000cb:	e8 2d 26 00 00       	call   f01026fd <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 40 06 00 00       	call   f010071d <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 33 36 10 f0       	push   $0xf0103633
f01000f7:	e8 01 26 00 00       	call   f01026fd <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 cf 25 00 00       	call   f01026d7 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 45 43 10 f0 	movl   $0xf0104345,(%esp)
f010010f:	e8 e9 25 00 00       	call   f01026fd <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 a0 37 10 f0 	movzbl -0xfefc860(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 a0 37 10 f0 	movzbl -0xfefc860(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a a0 36 10 f0 	movzbl -0xfefc960(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 80 36 10 f0 	mov    -0xfefc980(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 4d 36 10 f0       	push   $0xf010364d
f010026d:	e8 8b 24 00 00       	call   f01026fd <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 93 2d 00 00       	call   f01031b4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004c3:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004d4:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 59 36 10 f0       	push   $0xf0103659
f01005f0:	e8 08 21 00 00       	call   f01026fd <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 a0 38 10 f0       	push   $0xf01038a0
f0100636:	68 be 38 10 f0       	push   $0xf01038be
f010063b:	68 c3 38 10 f0       	push   $0xf01038c3
f0100640:	e8 b8 20 00 00       	call   f01026fd <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 2c 39 10 f0       	push   $0xf010392c
f010064d:	68 cc 38 10 f0       	push   $0xf01038cc
f0100652:	68 c3 38 10 f0       	push   $0xf01038c3
f0100657:	e8 a1 20 00 00       	call   f01026fd <cprintf>
	return 0;
}
f010065c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100661:	c9                   	leave  
f0100662:	c3                   	ret    

f0100663 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100669:	68 d5 38 10 f0       	push   $0xf01038d5
f010066e:	e8 8a 20 00 00       	call   f01026fd <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 54 39 10 f0       	push   $0xf0103954
f0100680:	e8 78 20 00 00       	call   f01026fd <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 7c 39 10 f0       	push   $0xf010397c
f0100697:	e8 61 20 00 00       	call   f01026fd <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 f1 35 10 00       	push   $0x1035f1
f01006a4:	68 f1 35 10 f0       	push   $0xf01035f1
f01006a9:	68 a0 39 10 f0       	push   $0xf01039a0
f01006ae:	e8 4a 20 00 00       	call   f01026fd <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 c4 39 10 f0       	push   $0xf01039c4
f01006c5:	e8 33 20 00 00       	call   f01026fd <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 70 69 11 00       	push   $0x116970
f01006d2:	68 70 69 11 f0       	push   $0xf0116970
f01006d7:	68 e8 39 10 f0       	push   $0xf01039e8
f01006dc:	e8 1c 20 00 00       	call   f01026fd <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
f01006e6:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006eb:	83 c4 08             	add    $0x8,%esp
f01006ee:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	0f 48 c2             	cmovs  %edx,%eax
f01006fe:	c1 f8 0a             	sar    $0xa,%eax
f0100701:	50                   	push   %eax
f0100702:	68 0c 3a 10 f0       	push   $0xf0103a0c
f0100707:	e8 f1 1f 00 00       	call   f01026fd <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100716:	b8 00 00 00 00       	mov    $0x0,%eax
f010071b:	5d                   	pop    %ebp
f010071c:	c3                   	ret    

f010071d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010071d:	55                   	push   %ebp
f010071e:	89 e5                	mov    %esp,%ebp
f0100720:	57                   	push   %edi
f0100721:	56                   	push   %esi
f0100722:	53                   	push   %ebx
f0100723:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100726:	68 38 3a 10 f0       	push   $0xf0103a38
f010072b:	e8 cd 1f 00 00       	call   f01026fd <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100730:	c7 04 24 5c 3a 10 f0 	movl   $0xf0103a5c,(%esp)
f0100737:	e8 c1 1f 00 00       	call   f01026fd <cprintf>
f010073c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010073f:	83 ec 0c             	sub    $0xc,%esp
f0100742:	68 ee 38 10 f0       	push   $0xf01038ee
f0100747:	e8 c4 27 00 00       	call   f0102f10 <readline>
f010074c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010074e:	83 c4 10             	add    $0x10,%esp
f0100751:	85 c0                	test   %eax,%eax
f0100753:	74 ea                	je     f010073f <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100755:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010075c:	be 00 00 00 00       	mov    $0x0,%esi
f0100761:	eb 0a                	jmp    f010076d <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100763:	c6 03 00             	movb   $0x0,(%ebx)
f0100766:	89 f7                	mov    %esi,%edi
f0100768:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010076b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010076d:	0f b6 03             	movzbl (%ebx),%eax
f0100770:	84 c0                	test   %al,%al
f0100772:	74 63                	je     f01007d7 <monitor+0xba>
f0100774:	83 ec 08             	sub    $0x8,%esp
f0100777:	0f be c0             	movsbl %al,%eax
f010077a:	50                   	push   %eax
f010077b:	68 f2 38 10 f0       	push   $0xf01038f2
f0100780:	e8 a5 29 00 00       	call   f010312a <strchr>
f0100785:	83 c4 10             	add    $0x10,%esp
f0100788:	85 c0                	test   %eax,%eax
f010078a:	75 d7                	jne    f0100763 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010078c:	80 3b 00             	cmpb   $0x0,(%ebx)
f010078f:	74 46                	je     f01007d7 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100791:	83 fe 0f             	cmp    $0xf,%esi
f0100794:	75 14                	jne    f01007aa <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100796:	83 ec 08             	sub    $0x8,%esp
f0100799:	6a 10                	push   $0x10
f010079b:	68 f7 38 10 f0       	push   $0xf01038f7
f01007a0:	e8 58 1f 00 00       	call   f01026fd <cprintf>
f01007a5:	83 c4 10             	add    $0x10,%esp
f01007a8:	eb 95                	jmp    f010073f <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007aa:	8d 7e 01             	lea    0x1(%esi),%edi
f01007ad:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007b1:	eb 03                	jmp    f01007b6 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007b3:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007b6:	0f b6 03             	movzbl (%ebx),%eax
f01007b9:	84 c0                	test   %al,%al
f01007bb:	74 ae                	je     f010076b <monitor+0x4e>
f01007bd:	83 ec 08             	sub    $0x8,%esp
f01007c0:	0f be c0             	movsbl %al,%eax
f01007c3:	50                   	push   %eax
f01007c4:	68 f2 38 10 f0       	push   $0xf01038f2
f01007c9:	e8 5c 29 00 00       	call   f010312a <strchr>
f01007ce:	83 c4 10             	add    $0x10,%esp
f01007d1:	85 c0                	test   %eax,%eax
f01007d3:	74 de                	je     f01007b3 <monitor+0x96>
f01007d5:	eb 94                	jmp    f010076b <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01007d7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007de:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007df:	85 f6                	test   %esi,%esi
f01007e1:	0f 84 58 ff ff ff    	je     f010073f <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007e7:	83 ec 08             	sub    $0x8,%esp
f01007ea:	68 be 38 10 f0       	push   $0xf01038be
f01007ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f2:	e8 d5 28 00 00       	call   f01030cc <strcmp>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 1e                	je     f010081c <monitor+0xff>
f01007fe:	83 ec 08             	sub    $0x8,%esp
f0100801:	68 cc 38 10 f0       	push   $0xf01038cc
f0100806:	ff 75 a8             	pushl  -0x58(%ebp)
f0100809:	e8 be 28 00 00       	call   f01030cc <strcmp>
f010080e:	83 c4 10             	add    $0x10,%esp
f0100811:	85 c0                	test   %eax,%eax
f0100813:	75 2f                	jne    f0100844 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100815:	b8 01 00 00 00       	mov    $0x1,%eax
f010081a:	eb 05                	jmp    f0100821 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010081c:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100821:	83 ec 04             	sub    $0x4,%esp
f0100824:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100827:	01 d0                	add    %edx,%eax
f0100829:	ff 75 08             	pushl  0x8(%ebp)
f010082c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010082f:	51                   	push   %ecx
f0100830:	56                   	push   %esi
f0100831:	ff 14 85 8c 3a 10 f0 	call   *-0xfefc574(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	85 c0                	test   %eax,%eax
f010083d:	78 1d                	js     f010085c <monitor+0x13f>
f010083f:	e9 fb fe ff ff       	jmp    f010073f <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100844:	83 ec 08             	sub    $0x8,%esp
f0100847:	ff 75 a8             	pushl  -0x58(%ebp)
f010084a:	68 14 39 10 f0       	push   $0xf0103914
f010084f:	e8 a9 1e 00 00       	call   f01026fd <cprintf>
f0100854:	83 c4 10             	add    $0x10,%esp
f0100857:	e9 e3 fe ff ff       	jmp    f010073f <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010085c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010085f:	5b                   	pop    %ebx
f0100860:	5e                   	pop    %esi
f0100861:	5f                   	pop    %edi
f0100862:	5d                   	pop    %ebp
f0100863:	c3                   	ret    

f0100864 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100864:	55                   	push   %ebp
f0100865:	89 e5                	mov    %esp,%ebp
f0100867:	56                   	push   %esi
f0100868:	53                   	push   %ebx
f0100869:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010086b:	83 ec 0c             	sub    $0xc,%esp
f010086e:	50                   	push   %eax
f010086f:	e8 22 1e 00 00       	call   f0102696 <mc146818_read>
f0100874:	89 c6                	mov    %eax,%esi
f0100876:	83 c3 01             	add    $0x1,%ebx
f0100879:	89 1c 24             	mov    %ebx,(%esp)
f010087c:	e8 15 1e 00 00       	call   f0102696 <mc146818_read>
f0100881:	c1 e0 08             	shl    $0x8,%eax
f0100884:	09 f0                	or     %esi,%eax
}
f0100886:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100889:	5b                   	pop    %ebx
f010088a:	5e                   	pop    %esi
f010088b:	5d                   	pop    %ebp
f010088c:	c3                   	ret    

f010088d <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010088d:	89 d1                	mov    %edx,%ecx
f010088f:	c1 e9 16             	shr    $0x16,%ecx
f0100892:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100895:	a8 01                	test   $0x1,%al
f0100897:	74 52                	je     f01008eb <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100899:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010089e:	89 c1                	mov    %eax,%ecx
f01008a0:	c1 e9 0c             	shr    $0xc,%ecx
f01008a3:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f01008a9:	72 1b                	jb     f01008c6 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01008ab:	55                   	push   %ebp
f01008ac:	89 e5                	mov    %esp,%ebp
f01008ae:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008b1:	50                   	push   %eax
f01008b2:	68 9c 3a 10 f0       	push   $0xf0103a9c
f01008b7:	68 15 03 00 00       	push   $0x315
f01008bc:	68 84 42 10 f0       	push   $0xf0104284
f01008c1:	e8 c5 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01008c6:	c1 ea 0c             	shr    $0xc,%edx
f01008c9:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01008cf:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01008d6:	89 c2                	mov    %eax,%edx
f01008d8:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01008db:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008e0:	85 d2                	test   %edx,%edx
f01008e2:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01008e7:	0f 44 c2             	cmove  %edx,%eax
f01008ea:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01008eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01008f0:	c3                   	ret    

f01008f1 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008f1:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008f8:	75 11                	jne    f010090b <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008fa:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f01008ff:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100905:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	//else// if not the first time (next free already has a value)
	if(n==0)
f010090b:	85 c0                	test   %eax,%eax
f010090d:	75 06                	jne    f0100915 <boot_alloc+0x24>
		return (void *)nextfree; // the result is the currently free place
f010090f:	a1 38 65 11 f0       	mov    0xf0116538,%eax
			return result;
		}
	}
	//panic("boot_alloc: This function is not finished\n");
	//return NULL;
}
f0100914:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100915:	55                   	push   %ebp
f0100916:	89 e5                	mov    %esp,%ebp
f0100918:	53                   	push   %ebx
f0100919:	83 ec 04             	sub    $0x4,%esp
f010091c:	89 c1                	mov    %eax,%ecx
	if(n==0)
		return (void *)nextfree; // the result is the currently free place
	else
	{
		// number of pages requested
		int numPagesRequested = ROUNDUP(n,PGSIZE)/PGSIZE;
f010091e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100924:	c1 ea 0c             	shr    $0xc,%edx
		// check if n exceeds memory panic
		//cprintf("%x,%x\n",PADDR(nextfree),numPagesRequested);
		if (npages<=(numPagesRequested + ((uint32_t)PADDR(nextfree)/PGSIZE)))
f0100927:	a1 38 65 11 f0       	mov    0xf0116538,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010092c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100931:	77 12                	ja     f0100945 <boot_alloc+0x54>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100933:	50                   	push   %eax
f0100934:	68 c0 3a 10 f0       	push   $0xf0103ac0
f0100939:	6a 79                	push   $0x79
f010093b:	68 84 42 10 f0       	push   $0xf0104284
f0100940:	e8 46 f7 ff ff       	call   f010008b <_panic>
f0100945:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f010094b:	c1 eb 0c             	shr    $0xc,%ebx
f010094e:	01 da                	add    %ebx,%edx
f0100950:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100956:	72 14                	jb     f010096c <boot_alloc+0x7b>
		{
			panic("boot_alloc: size of requested memory for allocation exceeds memory size\n");
f0100958:	83 ec 04             	sub    $0x4,%esp
f010095b:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0100960:	6a 7b                	push   $0x7b
f0100962:	68 84 42 10 f0       	push   $0xf0104284
f0100967:	e8 1f f7 ff ff       	call   f010008b <_panic>
			return NULL;
		}
		else
		{
			result = nextfree;
			nextfree = (char *)ROUNDUP(n + (uint32_t)nextfree, PGSIZE);
f010096c:	8d 94 08 ff 0f 00 00 	lea    0xfff(%eax,%ecx,1),%edx
f0100973:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100979:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
			return result;
		}
	}
	//panic("boot_alloc: This function is not finished\n");
	//return NULL;
}
f010097f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100982:	c9                   	leave  
f0100983:	c3                   	ret    

f0100984 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100984:	55                   	push   %ebp
f0100985:	89 e5                	mov    %esp,%ebp
f0100987:	57                   	push   %edi
f0100988:	56                   	push   %esi
f0100989:	53                   	push   %ebx
f010098a:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010098d:	84 c0                	test   %al,%al
f010098f:	0f 85 72 02 00 00    	jne    f0100c07 <check_page_free_list+0x283>
f0100995:	e9 7f 02 00 00       	jmp    f0100c19 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f010099a:	83 ec 04             	sub    $0x4,%esp
f010099d:	68 30 3b 10 f0       	push   $0xf0103b30
f01009a2:	68 58 02 00 00       	push   $0x258
f01009a7:	68 84 42 10 f0       	push   $0xf0104284
f01009ac:	e8 da f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009b1:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009b4:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009b7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009ba:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009bd:	89 c2                	mov    %eax,%edx
f01009bf:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01009c5:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009cb:	0f 95 c2             	setne  %dl
f01009ce:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009d1:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009d5:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009d7:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009db:	8b 00                	mov    (%eax),%eax
f01009dd:	85 c0                	test   %eax,%eax
f01009df:	75 dc                	jne    f01009bd <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009e4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009ed:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009f0:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009f2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009f5:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009fa:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009ff:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a05:	eb 53                	jmp    f0100a5a <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a07:	89 d8                	mov    %ebx,%eax
f0100a09:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100a0f:	c1 f8 03             	sar    $0x3,%eax
f0100a12:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a15:	89 c2                	mov    %eax,%edx
f0100a17:	c1 ea 16             	shr    $0x16,%edx
f0100a1a:	39 f2                	cmp    %esi,%edx
f0100a1c:	73 3a                	jae    f0100a58 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a1e:	89 c2                	mov    %eax,%edx
f0100a20:	c1 ea 0c             	shr    $0xc,%edx
f0100a23:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100a29:	72 12                	jb     f0100a3d <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a2b:	50                   	push   %eax
f0100a2c:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0100a31:	6a 52                	push   $0x52
f0100a33:	68 90 42 10 f0       	push   $0xf0104290
f0100a38:	e8 4e f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a3d:	83 ec 04             	sub    $0x4,%esp
f0100a40:	68 80 00 00 00       	push   $0x80
f0100a45:	68 97 00 00 00       	push   $0x97
f0100a4a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a4f:	50                   	push   %eax
f0100a50:	e8 12 27 00 00       	call   f0103167 <memset>
f0100a55:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a58:	8b 1b                	mov    (%ebx),%ebx
f0100a5a:	85 db                	test   %ebx,%ebx
f0100a5c:	75 a9                	jne    f0100a07 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a63:	e8 89 fe ff ff       	call   f01008f1 <boot_alloc>
f0100a68:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a6b:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a71:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100a77:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0100a7c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a7f:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a82:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a85:	be 00 00 00 00       	mov    $0x0,%esi
f0100a8a:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a8d:	e9 30 01 00 00       	jmp    f0100bc2 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a92:	39 ca                	cmp    %ecx,%edx
f0100a94:	73 19                	jae    f0100aaf <check_page_free_list+0x12b>
f0100a96:	68 9e 42 10 f0       	push   $0xf010429e
f0100a9b:	68 aa 42 10 f0       	push   $0xf01042aa
f0100aa0:	68 72 02 00 00       	push   $0x272
f0100aa5:	68 84 42 10 f0       	push   $0xf0104284
f0100aaa:	e8 dc f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100aaf:	39 fa                	cmp    %edi,%edx
f0100ab1:	72 19                	jb     f0100acc <check_page_free_list+0x148>
f0100ab3:	68 bf 42 10 f0       	push   $0xf01042bf
f0100ab8:	68 aa 42 10 f0       	push   $0xf01042aa
f0100abd:	68 73 02 00 00       	push   $0x273
f0100ac2:	68 84 42 10 f0       	push   $0xf0104284
f0100ac7:	e8 bf f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100acc:	89 d0                	mov    %edx,%eax
f0100ace:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ad1:	a8 07                	test   $0x7,%al
f0100ad3:	74 19                	je     f0100aee <check_page_free_list+0x16a>
f0100ad5:	68 54 3b 10 f0       	push   $0xf0103b54
f0100ada:	68 aa 42 10 f0       	push   $0xf01042aa
f0100adf:	68 74 02 00 00       	push   $0x274
f0100ae4:	68 84 42 10 f0       	push   $0xf0104284
f0100ae9:	e8 9d f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aee:	c1 f8 03             	sar    $0x3,%eax
f0100af1:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100af4:	85 c0                	test   %eax,%eax
f0100af6:	75 19                	jne    f0100b11 <check_page_free_list+0x18d>
f0100af8:	68 d3 42 10 f0       	push   $0xf01042d3
f0100afd:	68 aa 42 10 f0       	push   $0xf01042aa
f0100b02:	68 77 02 00 00       	push   $0x277
f0100b07:	68 84 42 10 f0       	push   $0xf0104284
f0100b0c:	e8 7a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b11:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b16:	75 19                	jne    f0100b31 <check_page_free_list+0x1ad>
f0100b18:	68 e4 42 10 f0       	push   $0xf01042e4
f0100b1d:	68 aa 42 10 f0       	push   $0xf01042aa
f0100b22:	68 78 02 00 00       	push   $0x278
f0100b27:	68 84 42 10 f0       	push   $0xf0104284
f0100b2c:	e8 5a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b31:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b36:	75 19                	jne    f0100b51 <check_page_free_list+0x1cd>
f0100b38:	68 88 3b 10 f0       	push   $0xf0103b88
f0100b3d:	68 aa 42 10 f0       	push   $0xf01042aa
f0100b42:	68 79 02 00 00       	push   $0x279
f0100b47:	68 84 42 10 f0       	push   $0xf0104284
f0100b4c:	e8 3a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b51:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b56:	75 19                	jne    f0100b71 <check_page_free_list+0x1ed>
f0100b58:	68 fd 42 10 f0       	push   $0xf01042fd
f0100b5d:	68 aa 42 10 f0       	push   $0xf01042aa
f0100b62:	68 7a 02 00 00       	push   $0x27a
f0100b67:	68 84 42 10 f0       	push   $0xf0104284
f0100b6c:	e8 1a f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b71:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b76:	76 3f                	jbe    f0100bb7 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b78:	89 c3                	mov    %eax,%ebx
f0100b7a:	c1 eb 0c             	shr    $0xc,%ebx
f0100b7d:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b80:	77 12                	ja     f0100b94 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b82:	50                   	push   %eax
f0100b83:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0100b88:	6a 52                	push   $0x52
f0100b8a:	68 90 42 10 f0       	push   $0xf0104290
f0100b8f:	e8 f7 f4 ff ff       	call   f010008b <_panic>
f0100b94:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b99:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b9c:	76 1e                	jbe    f0100bbc <check_page_free_list+0x238>
f0100b9e:	68 ac 3b 10 f0       	push   $0xf0103bac
f0100ba3:	68 aa 42 10 f0       	push   $0xf01042aa
f0100ba8:	68 7b 02 00 00       	push   $0x27b
f0100bad:	68 84 42 10 f0       	push   $0xf0104284
f0100bb2:	e8 d4 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bb7:	83 c6 01             	add    $0x1,%esi
f0100bba:	eb 04                	jmp    f0100bc0 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bbc:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bc0:	8b 12                	mov    (%edx),%edx
f0100bc2:	85 d2                	test   %edx,%edx
f0100bc4:	0f 85 c8 fe ff ff    	jne    f0100a92 <check_page_free_list+0x10e>
f0100bca:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bcd:	85 f6                	test   %esi,%esi
f0100bcf:	7f 19                	jg     f0100bea <check_page_free_list+0x266>
f0100bd1:	68 17 43 10 f0       	push   $0xf0104317
f0100bd6:	68 aa 42 10 f0       	push   $0xf01042aa
f0100bdb:	68 83 02 00 00       	push   $0x283
f0100be0:	68 84 42 10 f0       	push   $0xf0104284
f0100be5:	e8 a1 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100bea:	85 db                	test   %ebx,%ebx
f0100bec:	7f 42                	jg     f0100c30 <check_page_free_list+0x2ac>
f0100bee:	68 29 43 10 f0       	push   $0xf0104329
f0100bf3:	68 aa 42 10 f0       	push   $0xf01042aa
f0100bf8:	68 84 02 00 00       	push   $0x284
f0100bfd:	68 84 42 10 f0       	push   $0xf0104284
f0100c02:	e8 84 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c07:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c0c:	85 c0                	test   %eax,%eax
f0100c0e:	0f 85 9d fd ff ff    	jne    f01009b1 <check_page_free_list+0x2d>
f0100c14:	e9 81 fd ff ff       	jmp    f010099a <check_page_free_list+0x16>
f0100c19:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c20:	0f 84 74 fd ff ff    	je     f010099a <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c26:	be 00 04 00 00       	mov    $0x400,%esi
f0100c2b:	e9 cf fd ff ff       	jmp    f01009ff <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c30:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c33:	5b                   	pop    %ebx
f0100c34:	5e                   	pop    %esi
f0100c35:	5f                   	pop    %edi
f0100c36:	5d                   	pop    %ebp
f0100c37:	c3                   	ret    

f0100c38 <extractInt>:
#include <kern/kclock.h>

// Helping function to to extract bits from a 32-bit word
// The range of extracted bit is counted from right to left starting with index 0 to 32 INCLUSIVE
uint32_t extractInt(uint32_t orig32BitWord, unsigned from, unsigned to)
{
f0100c38:	55                   	push   %ebp
f0100c39:	89 e5                	mov    %esp,%ebp
f0100c3b:	8b 55 0c             	mov    0xc(%ebp),%edx
  unsigned mask = ( (1<<(to-from+1))-1) << from;
  return (orig32BitWord & mask) >> from;
f0100c3e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c41:	29 d1                	sub    %edx,%ecx
f0100c43:	83 c1 01             	add    $0x1,%ecx
f0100c46:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c4b:	d3 e0                	shl    %cl,%eax
f0100c4d:	83 e8 01             	sub    $0x1,%eax
f0100c50:	89 d1                	mov    %edx,%ecx
f0100c52:	d3 e0                	shl    %cl,%eax
f0100c54:	23 45 08             	and    0x8(%ebp),%eax
f0100c57:	d3 e8                	shr    %cl,%eax
}
f0100c59:	5d                   	pop    %ebp
f0100c5a:	c3                   	ret    

f0100c5b <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c5b:	55                   	push   %ebp
f0100c5c:	89 e5                	mov    %esp,%ebp
f0100c5e:	57                   	push   %edi
f0100c5f:	56                   	push   %esi
f0100c60:	53                   	push   %ebx
f0100c61:	83 ec 0c             	sub    $0xc,%esp
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages! [[what does this mean ?]]
	size_t i;
	// [[ Budy page will not be poiting to the first free space if the linked list gets updated!]]
	// 1)
	pages[0].pp_ref = 1; // in use
f0100c64:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100c69:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100c6f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// 2)
	//cprintf("num of pages in base memory : %d\n", npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100c75:	8b 35 40 65 11 f0    	mov    0xf0116540,%esi
f0100c7b:	8b 0d 3c 65 11 f0    	mov    0xf011653c,%ecx
f0100c81:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c86:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100c8b:	eb 27                	jmp    f0100cb4 <page_init+0x59>
		pages[i].pp_ref = 0;
f0100c8d:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100c94:	89 c2                	mov    %eax,%edx
f0100c96:	03 15 6c 69 11 f0    	add    0xf011696c,%edx
f0100c9c:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100ca2:	89 0a                	mov    %ecx,(%edx)
	pages[0].pp_ref = 1; // in use
	pages[0].pp_link = NULL;

	// 2)
	//cprintf("num of pages in base memory : %d\n", npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100ca4:	83 c3 01             	add    $0x1,%ebx
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100ca7:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100cad:	89 c1                	mov    %eax,%ecx
f0100caf:	b8 01 00 00 00       	mov    $0x1,%eax
	pages[0].pp_ref = 1; // in use
	pages[0].pp_link = NULL;

	// 2)
	//cprintf("num of pages in base memory : %d\n", npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100cb4:	39 f3                	cmp    %esi,%ebx
f0100cb6:	72 d5                	jb     f0100c8d <page_init+0x32>
f0100cb8:	84 c0                	test   %al,%al
f0100cba:	74 06                	je     f0100cc2 <page_init+0x67>
f0100cbc:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c
f0100cc2:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		page_free_list = &pages[i];
	}
	// 3)
	// number of pages in I/O hole = (IOPHYSMEM, EXTPHYSMEM)/PGSIZE
	// [[ why not (MMIOLIM - MMIOBASE)/PGSIZE ]]
	for (int tmp = i ; i < tmp + (EXTPHYSMEM - IOPHYSMEM)/PGSIZE ; i++)
f0100cc9:	8d 4b 60             	lea    0x60(%ebx),%ecx
f0100ccc:	eb 1a                	jmp    f0100ce8 <page_init+0x8d>
	{
		pages[i].pp_ref = 1;// busy [[ is there a way to gurantee it is always busy?]]
f0100cce:	89 c2                	mov    %eax,%edx
f0100cd0:	03 15 6c 69 11 f0    	add    0xf011696c,%edx
f0100cd6:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link = NULL; //[[ Do we need to point at next free in busy pages ? ]]
f0100cdc:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		page_free_list = &pages[i];
	}
	// 3)
	// number of pages in I/O hole = (IOPHYSMEM, EXTPHYSMEM)/PGSIZE
	// [[ why not (MMIOLIM - MMIOBASE)/PGSIZE ]]
	for (int tmp = i ; i < tmp + (EXTPHYSMEM - IOPHYSMEM)/PGSIZE ; i++)
f0100ce2:	83 c3 01             	add    $0x1,%ebx
f0100ce5:	83 c0 08             	add    $0x8,%eax
f0100ce8:	39 cb                	cmp    %ecx,%ebx
f0100cea:	72 e2                	jb     f0100cce <page_init+0x73>
f0100cec:	8d 3c dd 00 00 00 00 	lea    0x0(,%ebx,8),%edi
f0100cf3:	89 de                	mov    %ebx,%esi
f0100cf5:	eb 1a                	jmp    f0100d11 <page_init+0xb6>
	}
	//cprintf("%d , %d , %d\n", IOPHYSMEM, EXTPHYSMEM, (EXTPHYSMEM - IOPHYSMEM)/PGSIZE);
	// 4) [[ kernel reserved space is KSTKSIZE + KSTKGAP ??]]
	for (int tmp = i ; i < tmp + (PADDR(boot_alloc(0)) - EXTPHYSMEM)/PGSIZE ; i++)
	{
		pages[i].pp_ref = 1;// busy [[ is there a way to gurantee it is always busy?]]
f0100cf7:	89 f8                	mov    %edi,%eax
f0100cf9:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100cff:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
		pages[i].pp_link = NULL; //[[ Do we need to point at next free in busy pages ? ]]
f0100d05:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		pages[i].pp_ref = 1;// busy [[ is there a way to gurantee it is always busy?]]
		pages[i].pp_link = NULL; //[[ Do we need to point at next free in busy pages ? ]]
	}
	//cprintf("%d , %d , %d\n", IOPHYSMEM, EXTPHYSMEM, (EXTPHYSMEM - IOPHYSMEM)/PGSIZE);
	// 4) [[ kernel reserved space is KSTKSIZE + KSTKGAP ??]]
	for (int tmp = i ; i < tmp + (PADDR(boot_alloc(0)) - EXTPHYSMEM)/PGSIZE ; i++)
f0100d0b:	83 c6 01             	add    $0x1,%esi
f0100d0e:	83 c7 08             	add    $0x8,%edi
f0100d11:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d16:	e8 d6 fb ff ff       	call   f01008f1 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d1b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d20:	77 15                	ja     f0100d37 <page_init+0xdc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d22:	50                   	push   %eax
f0100d23:	68 c0 3a 10 f0       	push   $0xf0103ac0
f0100d28:	68 34 01 00 00       	push   $0x134
f0100d2d:	68 84 42 10 f0       	push   $0xf0104284
f0100d32:	e8 54 f3 ff ff       	call   f010008b <_panic>
f0100d37:	05 00 00 f0 0f       	add    $0xff00000,%eax
f0100d3c:	c1 e8 0c             	shr    $0xc,%eax
f0100d3f:	01 d8                	add    %ebx,%eax
f0100d41:	39 c6                	cmp    %eax,%esi
f0100d43:	72 b2                	jb     f0100cf7 <page_init+0x9c>
f0100d45:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d4b:	8d 14 f5 00 00 00 00 	lea    0x0(,%esi,8),%edx
f0100d52:	89 f1                	mov    %esi,%ecx
f0100d54:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d59:	eb 23                	jmp    f0100d7e <page_init+0x123>
		pages[i].pp_link = NULL; //[[ Do we need to point at next free in busy pages ? ]]
	}
	// The rest of the memory is free: npages - the number of pages allocated so far
	for (int tmp = i ; i < npages - tmp ; i++)
	{
		pages[i].pp_ref = 0;
f0100d5b:	89 d0                	mov    %edx,%eax
f0100d5d:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100d63:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100d69:	89 18                	mov    %ebx,(%eax)
		page_free_list = &pages[i];
f0100d6b:	89 d3                	mov    %edx,%ebx
f0100d6d:	03 1d 6c 69 11 f0    	add    0xf011696c,%ebx
	{
		pages[i].pp_ref = 1;// busy [[ is there a way to gurantee it is always busy?]]
		pages[i].pp_link = NULL; //[[ Do we need to point at next free in busy pages ? ]]
	}
	// The rest of the memory is free: npages - the number of pages allocated so far
	for (int tmp = i ; i < npages - tmp ; i++)
f0100d73:	83 c1 01             	add    $0x1,%ecx
f0100d76:	83 c2 08             	add    $0x8,%edx
f0100d79:	bf 01 00 00 00       	mov    $0x1,%edi
f0100d7e:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0100d83:	29 f0                	sub    %esi,%eax
f0100d85:	39 c1                	cmp    %eax,%ecx
f0100d87:	72 d2                	jb     f0100d5b <page_init+0x100>
f0100d89:	89 f8                	mov    %edi,%eax
f0100d8b:	84 c0                	test   %al,%al
f0100d8d:	74 06                	je     f0100d95 <page_init+0x13a>
f0100d8f:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
	{
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100d95:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d98:	5b                   	pop    %ebx
f0100d99:	5e                   	pop    %esi
f0100d9a:	5f                   	pop    %edi
f0100d9b:	5d                   	pop    %ebp
f0100d9c:	c3                   	ret    

f0100d9d <page_alloc>:
//
// Hint: use page2kva and memset
// page2kva from pageInfo to virtual address
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d9d:	55                   	push   %ebp
f0100d9e:	89 e5                	mov    %esp,%ebp
f0100da0:	53                   	push   %ebx
f0100da1:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
		if(!page_free_list) // null if out of free memory
f0100da4:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100daa:	85 db                	test   %ebx,%ebx
f0100dac:	74 58                	je     f0100e06 <page_alloc+0x69>
			return NULL;
		struct PageInfo * tmp = page_free_list; // tmp to store the pageInfo that will be filled
		page_free_list = (*tmp).pp_link; // The next free page is change to the next one
f0100dae:	8b 03                	mov    (%ebx),%eax
f0100db0:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
		(*tmp).pp_link = NULL; // indication that it is filled
f0100db5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if (alloc_flags & ALLOC_ZERO) // condition from the function comments
f0100dbb:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100dbf:	74 45                	je     f0100e06 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dc1:	89 d8                	mov    %ebx,%eax
f0100dc3:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100dc9:	c1 f8 03             	sar    $0x3,%eax
f0100dcc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dcf:	89 c2                	mov    %eax,%edx
f0100dd1:	c1 ea 0c             	shr    $0xc,%edx
f0100dd4:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100dda:	72 12                	jb     f0100dee <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ddc:	50                   	push   %eax
f0100ddd:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0100de2:	6a 52                	push   $0x52
f0100de4:	68 90 42 10 f0       	push   $0xf0104290
f0100de9:	e8 9d f2 ff ff       	call   f010008b <_panic>
			 memset(page2kva(tmp),'\0',PGSIZE); // fill the page with '\0'
f0100dee:	83 ec 04             	sub    $0x4,%esp
f0100df1:	68 00 10 00 00       	push   $0x1000
f0100df6:	6a 00                	push   $0x0
f0100df8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dfd:	50                   	push   %eax
f0100dfe:	e8 64 23 00 00       	call   f0103167 <memset>
f0100e03:	83 c4 10             	add    $0x10,%esp
		return tmp;
}
f0100e06:	89 d8                	mov    %ebx,%eax
f0100e08:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e0b:	c9                   	leave  
f0100e0c:	c3                   	ret    

f0100e0d <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e0d:	55                   	push   %ebp
f0100e0e:	89 e5                	mov    %esp,%ebp
f0100e10:	83 ec 08             	sub    $0x8,%esp
f0100e13:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link!= NULL)
f0100e16:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e1b:	75 05                	jne    f0100e22 <page_free+0x15>
f0100e1d:	83 38 00             	cmpl   $0x0,(%eax)
f0100e20:	74 17                	je     f0100e39 <page_free+0x2c>
		panic("page_free: reference count is non zero or next free page is not null");
f0100e22:	83 ec 04             	sub    $0x4,%esp
f0100e25:	68 f4 3b 10 f0       	push   $0xf0103bf4
f0100e2a:	68 68 01 00 00       	push   $0x168
f0100e2f:	68 84 42 10 f0       	push   $0xf0104284
f0100e34:	e8 52 f2 ff ff       	call   f010008b <_panic>
	struct PageInfo * tmp = page_free_list;
f0100e39:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
	page_free_list = pp;
f0100e3f:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	(*pp).pp_link = tmp;
f0100e44:	89 10                	mov    %edx,(%eax)
}
f0100e46:	c9                   	leave  
f0100e47:	c3                   	ret    

f0100e48 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e48:	55                   	push   %ebp
f0100e49:	89 e5                	mov    %esp,%ebp
f0100e4b:	83 ec 08             	sub    $0x8,%esp
f0100e4e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e51:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e55:	83 e8 01             	sub    $0x1,%eax
f0100e58:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e5c:	66 85 c0             	test   %ax,%ax
f0100e5f:	75 0c                	jne    f0100e6d <page_decref+0x25>
		page_free(pp);
f0100e61:	83 ec 0c             	sub    $0xc,%esp
f0100e64:	52                   	push   %edx
f0100e65:	e8 a3 ff ff ff       	call   f0100e0d <page_free>
f0100e6a:	83 c4 10             	add    $0x10,%esp
}
f0100e6d:	c9                   	leave  
f0100e6e:	c3                   	ret    

f0100e6f <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e6f:	55                   	push   %ebp
f0100e70:	89 e5                	mov    %esp,%ebp
f0100e72:	56                   	push   %esi
f0100e73:	53                   	push   %ebx
f0100e74:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  // Extracting the left most 10 bits in the virtual address = page dir. offset
  uint32_t pg_dir_offset =  PDX(va);
  // Extracting the mid 10 bits in the virtual address = page table offset
  uint32_t pg_table_offset = PTX(va);
f0100e77:	89 de                	mov    %ebx,%esi
f0100e79:	c1 ee 0c             	shr    $0xc,%esi
f0100e7c:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
  // if page table not loaded in physical memory by checking present bit
  if (!(pgdir[pg_dir_offset] & PTE_P))
f0100e82:	c1 eb 16             	shr    $0x16,%ebx
f0100e85:	c1 e3 02             	shl    $0x2,%ebx
f0100e88:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e8b:	f6 03 01             	testb  $0x1,(%ebx)
f0100e8e:	75 2f                	jne    f0100ebf <pgdir_walk+0x50>
  {
    // return null if create is not set
    if(!create)
f0100e90:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e94:	74 5b                	je     f0100ef1 <pgdir_walk+0x82>
      return NULL;
    else // allocate a page
    {
      // store page info in struct PageInfo
      struct PageInfo * pg_info = page_alloc(ALLOC_ZERO);
f0100e96:	83 ec 0c             	sub    $0xc,%esp
f0100e99:	6a 01                	push   $0x1
f0100e9b:	e8 fd fe ff ff       	call   f0100d9d <page_alloc>
      // if allocation fails return NULL
      if(!pg_info)
f0100ea0:	83 c4 10             	add    $0x10,%esp
f0100ea3:	85 c0                	test   %eax,%eax
f0100ea5:	74 51                	je     f0100ef8 <pgdir_walk+0x89>
        return NULL;
      else // increment reference count
      {
        pg_info->pp_ref +=1;
f0100ea7:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
        // map the va to the physical address setting the present bit
        // Started with present bit only then it gave assertion failed because PTE_U is missing so we added the rest of the flags
        // [[Though we do not understand the meaning of those flags PTE_WT(write through) | PTE_AVAIL(system available)]]
        pgdir[pg_dir_offset] = page2pa(pg_info) | PTE_P | PTE_U| PTE_W | PTE_PWT | PTE_AVAIL;
f0100eac:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100eb2:	c1 f8 03             	sar    $0x3,%eax
f0100eb5:	c1 e0 0c             	shl    $0xc,%eax
f0100eb8:	0d 0f 0e 00 00       	or     $0xe0f,%eax
f0100ebd:	89 03                	mov    %eax,(%ebx)
    }
  }
  // page table entry in page directory
  pte_t pte_in_pgdir = *(pgdir + pg_dir_offset);
  // Physical address in page table or page directory entry (left most 20 bits)
  pte_t pg_table_addr = PTE_ADDR(pte_in_pgdir);
f0100ebf:	8b 03                	mov    (%ebx),%eax
f0100ec1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ec6:	89 c2                	mov    %eax,%edx
f0100ec8:	c1 ea 0c             	shr    $0xc,%edx
f0100ecb:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100ed1:	72 15                	jb     f0100ee8 <pgdir_walk+0x79>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ed3:	50                   	push   %eax
f0100ed4:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0100ed9:	68 b3 01 00 00       	push   $0x1b3
f0100ede:	68 84 42 10 f0       	push   $0xf0104284
f0100ee3:	e8 a3 f1 ff ff       	call   f010008b <_panic>
  // get virtual address of the page table entry by adding the
  pte_t * pg_table_entry = (pde_t *)KADDR(pg_table_addr)+pg_table_offset;
  return pg_table_entry;
f0100ee8:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100eef:	eb 0c                	jmp    f0100efd <pgdir_walk+0x8e>
  // if page table not loaded in physical memory by checking present bit
  if (!(pgdir[pg_dir_offset] & PTE_P))
  {
    // return null if create is not set
    if(!create)
      return NULL;
f0100ef1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef6:	eb 05                	jmp    f0100efd <pgdir_walk+0x8e>
    {
      // store page info in struct PageInfo
      struct PageInfo * pg_info = page_alloc(ALLOC_ZERO);
      // if allocation fails return NULL
      if(!pg_info)
        return NULL;
f0100ef8:	b8 00 00 00 00       	mov    $0x0,%eax
  // Physical address in page table or page directory entry (left most 20 bits)
  pte_t pg_table_addr = PTE_ADDR(pte_in_pgdir);
  // get virtual address of the page table entry by adding the
  pte_t * pg_table_entry = (pde_t *)KADDR(pg_table_addr)+pg_table_offset;
  return pg_table_entry;
}
f0100efd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f00:	5b                   	pop    %ebx
f0100f01:	5e                   	pop    %esi
f0100f02:	5d                   	pop    %ebp
f0100f03:	c3                   	ret    

f0100f04 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f04:	55                   	push   %ebp
f0100f05:	89 e5                	mov    %esp,%ebp
f0100f07:	57                   	push   %edi
f0100f08:	56                   	push   %esi
f0100f09:	53                   	push   %ebx
f0100f0a:	83 ec 1c             	sub    $0x1c,%esp
f0100f0d:	89 c7                	mov    %eax,%edi
f0100f0f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f12:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
  for (int i = 0; i < size; i += PGSIZE, va += PGSIZE) {
f0100f15:	bb 00 00 00 00       	mov    $0x0,%ebx
  pte_t * temp = pgdir_walk(pgdir, (void *)va, 1); //create flag?!!!!!
  //TODO ha3mel 7aga bel temp
  //TODO ha3mel 7aga bel pa & perm
  *temp = pa | perm | PTE_P;
f0100f1a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f1d:	83 c8 01             	or     $0x1,%eax
f0100f20:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
  for (int i = 0; i < size; i += PGSIZE, va += PGSIZE) {
f0100f23:	eb 1f                	jmp    f0100f44 <boot_map_region+0x40>
  pte_t * temp = pgdir_walk(pgdir, (void *)va, 1); //create flag?!!!!!
f0100f25:	83 ec 04             	sub    $0x4,%esp
f0100f28:	6a 01                	push   $0x1
f0100f2a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f2d:	01 d8                	add    %ebx,%eax
f0100f2f:	50                   	push   %eax
f0100f30:	57                   	push   %edi
f0100f31:	e8 39 ff ff ff       	call   f0100e6f <pgdir_walk>
  //TODO ha3mel 7aga bel temp
  //TODO ha3mel 7aga bel pa & perm
  *temp = pa | perm | PTE_P;
f0100f36:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100f39:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
  for (int i = 0; i < size; i += PGSIZE, va += PGSIZE) {
f0100f3b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f41:	83 c4 10             	add    $0x10,%esp
f0100f44:	89 de                	mov    %ebx,%esi
f0100f46:	03 75 08             	add    0x8(%ebp),%esi
f0100f49:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100f4c:	77 d7                	ja     f0100f25 <boot_map_region+0x21>
  //TODO ha3mel 7aga bel temp
  //TODO ha3mel 7aga bel pa & perm
  *temp = pa | perm | PTE_P;
  pa += PGSIZE;
  }
}
f0100f4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f51:	5b                   	pop    %ebx
f0100f52:	5e                   	pop    %esi
f0100f53:	5f                   	pop    %edi
f0100f54:	5d                   	pop    %ebp
f0100f55:	c3                   	ret    

f0100f56 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f56:	55                   	push   %ebp
f0100f57:	89 e5                	mov    %esp,%ebp
f0100f59:	53                   	push   %ebx
f0100f5a:	83 ec 08             	sub    $0x8,%esp
f0100f5d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t * pg_table_entry = pgdir_walk(pgdir,va,0); // 0 cuz no need to create it is just lookup
f0100f60:	6a 00                	push   $0x0
f0100f62:	ff 75 0c             	pushl  0xc(%ebp)
f0100f65:	ff 75 08             	pushl  0x8(%ebp)
f0100f68:	e8 02 ff ff ff       	call   f0100e6f <pgdir_walk>
  if(pg_table_entry == NULL )
f0100f6d:	83 c4 10             	add    $0x10,%esp
f0100f70:	85 c0                	test   %eax,%eax
f0100f72:	74 32                	je     f0100fa6 <page_lookup+0x50>
  {
    // va not mapped
    return NULL;
  }
  if(pte_store != 0 )
f0100f74:	85 db                	test   %ebx,%ebx
f0100f76:	74 02                	je     f0100f7a <page_lookup+0x24>
  {
    *pte_store = pg_table_entry;
f0100f78:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f7a:	8b 00                	mov    (%eax),%eax
f0100f7c:	c1 e8 0c             	shr    $0xc,%eax
f0100f7f:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100f85:	72 14                	jb     f0100f9b <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100f87:	83 ec 04             	sub    $0x4,%esp
f0100f8a:	68 3c 3c 10 f0       	push   $0xf0103c3c
f0100f8f:	6a 4b                	push   $0x4b
f0100f91:	68 90 42 10 f0       	push   $0xf0104290
f0100f96:	e8 f0 f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f9b:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100fa1:	8d 04 c2             	lea    (%edx,%eax,8),%eax
  }
	struct PageInfo * p = pa2page(PTE_ADDR(*pg_table_entry));
  return p;
f0100fa4:	eb 05                	jmp    f0100fab <page_lookup+0x55>
{
	pte_t * pg_table_entry = pgdir_walk(pgdir,va,0); // 0 cuz no need to create it is just lookup
  if(pg_table_entry == NULL )
  {
    // va not mapped
    return NULL;
f0100fa6:	b8 00 00 00 00       	mov    $0x0,%eax
  {
    *pte_store = pg_table_entry;
  }
	struct PageInfo * p = pa2page(PTE_ADDR(*pg_table_entry));
  return p;
}
f0100fab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fae:	c9                   	leave  
f0100faf:	c3                   	ret    

f0100fb0 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fb0:	55                   	push   %ebp
f0100fb1:	89 e5                	mov    %esp,%ebp
f0100fb3:	53                   	push   %ebx
f0100fb4:	83 ec 18             	sub    $0x18,%esp
f0100fb7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  pte_t * pte_of_va;
  struct PageInfo * pg_info = page_lookup(pgdir, va,&pte_of_va);
f0100fba:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fbd:	50                   	push   %eax
f0100fbe:	53                   	push   %ebx
f0100fbf:	ff 75 08             	pushl  0x8(%ebp)
f0100fc2:	e8 8f ff ff ff       	call   f0100f56 <page_lookup>
  if(pg_info == NULL)// Meaning no physical page attached to va
f0100fc7:	83 c4 10             	add    $0x10,%esp
f0100fca:	85 c0                	test   %eax,%eax
f0100fcc:	74 18                	je     f0100fe6 <page_remove+0x36>
    return;
  // if the physical page exists:
  page_decref(pg_info);
f0100fce:	83 ec 0c             	sub    $0xc,%esp
f0100fd1:	50                   	push   %eax
f0100fd2:	e8 71 fe ff ff       	call   f0100e48 <page_decref>
  *pte_of_va = 0;
f0100fd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fda:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fe0:	0f 01 3b             	invlpg (%ebx)
f0100fe3:	83 c4 10             	add    $0x10,%esp
  tlb_invalidate(pgdir,va);

}
f0100fe6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fe9:	c9                   	leave  
f0100fea:	c3                   	ret    

f0100feb <page_insert>:
//
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100feb:	55                   	push   %ebp
f0100fec:	89 e5                	mov    %esp,%ebp
f0100fee:	57                   	push   %edi
f0100fef:	56                   	push   %esi
f0100ff0:	53                   	push   %ebx
f0100ff1:	83 ec 10             	sub    $0x10,%esp
f0100ff4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	int permissions = perm | PTE_P;
f0100ff7:	8b 75 14             	mov    0x14(%ebp),%esi
f0100ffa:	83 ce 01             	or     $0x1,%esi
	//cprintf("Permissions: %d \n",permissions);
  // get page table entry
  pte_t * pg_table_entry = pgdir_walk(pgdir,va,1);
f0100ffd:	6a 01                	push   $0x1
f0100fff:	ff 75 10             	pushl  0x10(%ebp)
f0101002:	ff 75 08             	pushl  0x8(%ebp)
f0101005:	e8 65 fe ff ff       	call   f0100e6f <pgdir_walk>
  if(pg_table_entry == NULL) // page table could not be allocated cuz memory full
f010100a:	83 c4 10             	add    $0x10,%esp
f010100d:	85 c0                	test   %eax,%eax
f010100f:	74 34                	je     f0101045 <page_insert+0x5a>
f0101011:	89 c7                	mov    %eax,%edi
    return -E_NO_MEM;

      pp->pp_ref +=1;
f0101013:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
      //[[The TLB must be invalidated (??!!) if a page was formerly present at 'va'??]]
      // if the virtual page is mapping to another page you need to remove this mapping first and free that physical page
      // [[Why would a virtual page care to map to another physical page ??]]
      // [[handling the same pp inserted at the same va ?? should the ref_count be unchanged? ]]
      if (*pg_table_entry & PTE_P)
f0101018:	f6 00 01             	testb  $0x1,(%eax)
f010101b:	74 11                	je     f010102e <page_insert+0x43>
      { // if the virtual page was assigned to another phsical the mapping should be removed
        // This will free physical memory if it was the only one pointing at it
        //remove before assigning the physical page
        page_remove(pgdir, va);
f010101d:	83 ec 08             	sub    $0x8,%esp
f0101020:	ff 75 10             	pushl  0x10(%ebp)
f0101023:	ff 75 08             	pushl  0x8(%ebp)
f0101026:	e8 85 ff ff ff       	call   f0100fb0 <page_remove>
f010102b:	83 c4 10             	add    $0x10,%esp
      }
      *pg_table_entry = page2pa(pp) | permissions;
f010102e:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0101034:	c1 fb 03             	sar    $0x3,%ebx
f0101037:	c1 e3 0c             	shl    $0xc,%ebx
f010103a:	09 de                	or     %ebx,%esi
f010103c:	89 37                	mov    %esi,(%edi)
	return 0;
f010103e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101043:	eb 05                	jmp    f010104a <page_insert+0x5f>
	int permissions = perm | PTE_P;
	//cprintf("Permissions: %d \n",permissions);
  // get page table entry
  pte_t * pg_table_entry = pgdir_walk(pgdir,va,1);
  if(pg_table_entry == NULL) // page table could not be allocated cuz memory full
    return -E_NO_MEM;
f0101045:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
        //remove before assigning the physical page
        page_remove(pgdir, va);
      }
      *pg_table_entry = page2pa(pp) | permissions;
	return 0;
}
f010104a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010104d:	5b                   	pop    %ebx
f010104e:	5e                   	pop    %esi
f010104f:	5f                   	pop    %edi
f0101050:	5d                   	pop    %ebp
f0101051:	c3                   	ret    

f0101052 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101052:	55                   	push   %ebp
f0101053:	89 e5                	mov    %esp,%ebp
f0101055:	57                   	push   %edi
f0101056:	56                   	push   %esi
f0101057:	53                   	push   %ebx
f0101058:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010105b:	b8 15 00 00 00       	mov    $0x15,%eax
f0101060:	e8 ff f7 ff ff       	call   f0100864 <nvram_read>
f0101065:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101067:	b8 17 00 00 00       	mov    $0x17,%eax
f010106c:	e8 f3 f7 ff ff       	call   f0100864 <nvram_read>
f0101071:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101073:	b8 34 00 00 00       	mov    $0x34,%eax
f0101078:	e8 e7 f7 ff ff       	call   f0100864 <nvram_read>
f010107d:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101080:	85 c0                	test   %eax,%eax
f0101082:	74 07                	je     f010108b <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101084:	05 00 40 00 00       	add    $0x4000,%eax
f0101089:	eb 0b                	jmp    f0101096 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010108b:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101091:	85 f6                	test   %esi,%esi
f0101093:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101096:	89 c2                	mov    %eax,%edx
f0101098:	c1 ea 02             	shr    $0x2,%edx
f010109b:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
	npages_basemem = basemem / (PGSIZE / 1024);
f01010a1:	89 da                	mov    %ebx,%edx
f01010a3:	c1 ea 02             	shr    $0x2,%edx
f01010a6:	89 15 40 65 11 f0    	mov    %edx,0xf0116540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010ac:	89 c2                	mov    %eax,%edx
f01010ae:	29 da                	sub    %ebx,%edx
f01010b0:	52                   	push   %edx
f01010b1:	53                   	push   %ebx
f01010b2:	50                   	push   %eax
f01010b3:	68 5c 3c 10 f0       	push   $0xf0103c5c
f01010b8:	e8 40 16 00 00       	call   f01026fd <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010bd:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010c2:	e8 2a f8 ff ff       	call   f01008f1 <boot_alloc>
f01010c7:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f01010cc:	83 c4 0c             	add    $0xc,%esp
f01010cf:	68 00 10 00 00       	push   $0x1000
f01010d4:	6a 00                	push   $0x0
f01010d6:	50                   	push   %eax
f01010d7:	e8 8b 20 00 00       	call   f0103167 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010dc:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010e1:	83 c4 10             	add    $0x10,%esp
f01010e4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010e9:	77 15                	ja     f0101100 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010eb:	50                   	push   %eax
f01010ec:	68 c0 3a 10 f0       	push   $0xf0103ac0
f01010f1:	68 aa 00 00 00       	push   $0xaa
f01010f6:	68 84 42 10 f0       	push   $0xf0104284
f01010fb:	e8 8b ef ff ff       	call   f010008b <_panic>
f0101100:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101106:	83 ca 05             	or     $0x5,%edx
f0101109:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages*sizeof(struct PageInfo));
f010110f:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101114:	c1 e0 03             	shl    $0x3,%eax
f0101117:	e8 d5 f7 ff ff       	call   f01008f1 <boot_alloc>
f010111c:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101121:	e8 35 fb ff ff       	call   f0100c5b <page_init>
		cprintf("npages: %x \n", npages);
f0101126:	83 ec 08             	sub    $0x8,%esp
f0101129:	ff 35 64 69 11 f0    	pushl  0xf0116964
f010112f:	68 3a 43 10 f0       	push   $0xf010433a
f0101134:	e8 c4 15 00 00       	call   f01026fd <cprintf>
	check_page_free_list(1);
f0101139:	b8 01 00 00 00       	mov    $0x1,%eax
f010113e:	e8 41 f8 ff ff       	call   f0100984 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101143:	83 c4 10             	add    $0x10,%esp
f0101146:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f010114d:	75 17                	jne    f0101166 <mem_init+0x114>
		panic("'pages' is a null pointer!");
f010114f:	83 ec 04             	sub    $0x4,%esp
f0101152:	68 47 43 10 f0       	push   $0xf0104347
f0101157:	68 95 02 00 00       	push   $0x295
f010115c:	68 84 42 10 f0       	push   $0xf0104284
f0101161:	e8 25 ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101166:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010116b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101170:	eb 05                	jmp    f0101177 <mem_init+0x125>
		++nfree;
f0101172:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101175:	8b 00                	mov    (%eax),%eax
f0101177:	85 c0                	test   %eax,%eax
f0101179:	75 f7                	jne    f0101172 <mem_init+0x120>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010117b:	83 ec 0c             	sub    $0xc,%esp
f010117e:	6a 00                	push   $0x0
f0101180:	e8 18 fc ff ff       	call   f0100d9d <page_alloc>
f0101185:	89 c7                	mov    %eax,%edi
f0101187:	83 c4 10             	add    $0x10,%esp
f010118a:	85 c0                	test   %eax,%eax
f010118c:	75 19                	jne    f01011a7 <mem_init+0x155>
f010118e:	68 62 43 10 f0       	push   $0xf0104362
f0101193:	68 aa 42 10 f0       	push   $0xf01042aa
f0101198:	68 9d 02 00 00       	push   $0x29d
f010119d:	68 84 42 10 f0       	push   $0xf0104284
f01011a2:	e8 e4 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011a7:	83 ec 0c             	sub    $0xc,%esp
f01011aa:	6a 00                	push   $0x0
f01011ac:	e8 ec fb ff ff       	call   f0100d9d <page_alloc>
f01011b1:	89 c6                	mov    %eax,%esi
f01011b3:	83 c4 10             	add    $0x10,%esp
f01011b6:	85 c0                	test   %eax,%eax
f01011b8:	75 19                	jne    f01011d3 <mem_init+0x181>
f01011ba:	68 78 43 10 f0       	push   $0xf0104378
f01011bf:	68 aa 42 10 f0       	push   $0xf01042aa
f01011c4:	68 9e 02 00 00       	push   $0x29e
f01011c9:	68 84 42 10 f0       	push   $0xf0104284
f01011ce:	e8 b8 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011d3:	83 ec 0c             	sub    $0xc,%esp
f01011d6:	6a 00                	push   $0x0
f01011d8:	e8 c0 fb ff ff       	call   f0100d9d <page_alloc>
f01011dd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011e0:	83 c4 10             	add    $0x10,%esp
f01011e3:	85 c0                	test   %eax,%eax
f01011e5:	75 19                	jne    f0101200 <mem_init+0x1ae>
f01011e7:	68 8e 43 10 f0       	push   $0xf010438e
f01011ec:	68 aa 42 10 f0       	push   $0xf01042aa
f01011f1:	68 9f 02 00 00       	push   $0x29f
f01011f6:	68 84 42 10 f0       	push   $0xf0104284
f01011fb:	e8 8b ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101200:	39 f7                	cmp    %esi,%edi
f0101202:	75 19                	jne    f010121d <mem_init+0x1cb>
f0101204:	68 a4 43 10 f0       	push   $0xf01043a4
f0101209:	68 aa 42 10 f0       	push   $0xf01042aa
f010120e:	68 a2 02 00 00       	push   $0x2a2
f0101213:	68 84 42 10 f0       	push   $0xf0104284
f0101218:	e8 6e ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010121d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101220:	39 c6                	cmp    %eax,%esi
f0101222:	74 04                	je     f0101228 <mem_init+0x1d6>
f0101224:	39 c7                	cmp    %eax,%edi
f0101226:	75 19                	jne    f0101241 <mem_init+0x1ef>
f0101228:	68 98 3c 10 f0       	push   $0xf0103c98
f010122d:	68 aa 42 10 f0       	push   $0xf01042aa
f0101232:	68 a3 02 00 00       	push   $0x2a3
f0101237:	68 84 42 10 f0       	push   $0xf0104284
f010123c:	e8 4a ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101241:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101247:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f010124d:	c1 e2 0c             	shl    $0xc,%edx
f0101250:	89 f8                	mov    %edi,%eax
f0101252:	29 c8                	sub    %ecx,%eax
f0101254:	c1 f8 03             	sar    $0x3,%eax
f0101257:	c1 e0 0c             	shl    $0xc,%eax
f010125a:	39 d0                	cmp    %edx,%eax
f010125c:	72 19                	jb     f0101277 <mem_init+0x225>
f010125e:	68 b6 43 10 f0       	push   $0xf01043b6
f0101263:	68 aa 42 10 f0       	push   $0xf01042aa
f0101268:	68 a4 02 00 00       	push   $0x2a4
f010126d:	68 84 42 10 f0       	push   $0xf0104284
f0101272:	e8 14 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101277:	89 f0                	mov    %esi,%eax
f0101279:	29 c8                	sub    %ecx,%eax
f010127b:	c1 f8 03             	sar    $0x3,%eax
f010127e:	c1 e0 0c             	shl    $0xc,%eax
f0101281:	39 c2                	cmp    %eax,%edx
f0101283:	77 19                	ja     f010129e <mem_init+0x24c>
f0101285:	68 d3 43 10 f0       	push   $0xf01043d3
f010128a:	68 aa 42 10 f0       	push   $0xf01042aa
f010128f:	68 a5 02 00 00       	push   $0x2a5
f0101294:	68 84 42 10 f0       	push   $0xf0104284
f0101299:	e8 ed ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010129e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012a1:	29 c8                	sub    %ecx,%eax
f01012a3:	c1 f8 03             	sar    $0x3,%eax
f01012a6:	c1 e0 0c             	shl    $0xc,%eax
f01012a9:	39 c2                	cmp    %eax,%edx
f01012ab:	77 19                	ja     f01012c6 <mem_init+0x274>
f01012ad:	68 f0 43 10 f0       	push   $0xf01043f0
f01012b2:	68 aa 42 10 f0       	push   $0xf01042aa
f01012b7:	68 a6 02 00 00       	push   $0x2a6
f01012bc:	68 84 42 10 f0       	push   $0xf0104284
f01012c1:	e8 c5 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012c6:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012cb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012ce:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012d5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012d8:	83 ec 0c             	sub    $0xc,%esp
f01012db:	6a 00                	push   $0x0
f01012dd:	e8 bb fa ff ff       	call   f0100d9d <page_alloc>
f01012e2:	83 c4 10             	add    $0x10,%esp
f01012e5:	85 c0                	test   %eax,%eax
f01012e7:	74 19                	je     f0101302 <mem_init+0x2b0>
f01012e9:	68 0d 44 10 f0       	push   $0xf010440d
f01012ee:	68 aa 42 10 f0       	push   $0xf01042aa
f01012f3:	68 ad 02 00 00       	push   $0x2ad
f01012f8:	68 84 42 10 f0       	push   $0xf0104284
f01012fd:	e8 89 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101302:	83 ec 0c             	sub    $0xc,%esp
f0101305:	57                   	push   %edi
f0101306:	e8 02 fb ff ff       	call   f0100e0d <page_free>
	page_free(pp1);
f010130b:	89 34 24             	mov    %esi,(%esp)
f010130e:	e8 fa fa ff ff       	call   f0100e0d <page_free>
	page_free(pp2);
f0101313:	83 c4 04             	add    $0x4,%esp
f0101316:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101319:	e8 ef fa ff ff       	call   f0100e0d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010131e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101325:	e8 73 fa ff ff       	call   f0100d9d <page_alloc>
f010132a:	89 c6                	mov    %eax,%esi
f010132c:	83 c4 10             	add    $0x10,%esp
f010132f:	85 c0                	test   %eax,%eax
f0101331:	75 19                	jne    f010134c <mem_init+0x2fa>
f0101333:	68 62 43 10 f0       	push   $0xf0104362
f0101338:	68 aa 42 10 f0       	push   $0xf01042aa
f010133d:	68 b4 02 00 00       	push   $0x2b4
f0101342:	68 84 42 10 f0       	push   $0xf0104284
f0101347:	e8 3f ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010134c:	83 ec 0c             	sub    $0xc,%esp
f010134f:	6a 00                	push   $0x0
f0101351:	e8 47 fa ff ff       	call   f0100d9d <page_alloc>
f0101356:	89 c7                	mov    %eax,%edi
f0101358:	83 c4 10             	add    $0x10,%esp
f010135b:	85 c0                	test   %eax,%eax
f010135d:	75 19                	jne    f0101378 <mem_init+0x326>
f010135f:	68 78 43 10 f0       	push   $0xf0104378
f0101364:	68 aa 42 10 f0       	push   $0xf01042aa
f0101369:	68 b5 02 00 00       	push   $0x2b5
f010136e:	68 84 42 10 f0       	push   $0xf0104284
f0101373:	e8 13 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101378:	83 ec 0c             	sub    $0xc,%esp
f010137b:	6a 00                	push   $0x0
f010137d:	e8 1b fa ff ff       	call   f0100d9d <page_alloc>
f0101382:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101385:	83 c4 10             	add    $0x10,%esp
f0101388:	85 c0                	test   %eax,%eax
f010138a:	75 19                	jne    f01013a5 <mem_init+0x353>
f010138c:	68 8e 43 10 f0       	push   $0xf010438e
f0101391:	68 aa 42 10 f0       	push   $0xf01042aa
f0101396:	68 b6 02 00 00       	push   $0x2b6
f010139b:	68 84 42 10 f0       	push   $0xf0104284
f01013a0:	e8 e6 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013a5:	39 fe                	cmp    %edi,%esi
f01013a7:	75 19                	jne    f01013c2 <mem_init+0x370>
f01013a9:	68 a4 43 10 f0       	push   $0xf01043a4
f01013ae:	68 aa 42 10 f0       	push   $0xf01042aa
f01013b3:	68 b8 02 00 00       	push   $0x2b8
f01013b8:	68 84 42 10 f0       	push   $0xf0104284
f01013bd:	e8 c9 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013c2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013c5:	39 c7                	cmp    %eax,%edi
f01013c7:	74 04                	je     f01013cd <mem_init+0x37b>
f01013c9:	39 c6                	cmp    %eax,%esi
f01013cb:	75 19                	jne    f01013e6 <mem_init+0x394>
f01013cd:	68 98 3c 10 f0       	push   $0xf0103c98
f01013d2:	68 aa 42 10 f0       	push   $0xf01042aa
f01013d7:	68 b9 02 00 00       	push   $0x2b9
f01013dc:	68 84 42 10 f0       	push   $0xf0104284
f01013e1:	e8 a5 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013e6:	83 ec 0c             	sub    $0xc,%esp
f01013e9:	6a 00                	push   $0x0
f01013eb:	e8 ad f9 ff ff       	call   f0100d9d <page_alloc>
f01013f0:	83 c4 10             	add    $0x10,%esp
f01013f3:	85 c0                	test   %eax,%eax
f01013f5:	74 19                	je     f0101410 <mem_init+0x3be>
f01013f7:	68 0d 44 10 f0       	push   $0xf010440d
f01013fc:	68 aa 42 10 f0       	push   $0xf01042aa
f0101401:	68 ba 02 00 00       	push   $0x2ba
f0101406:	68 84 42 10 f0       	push   $0xf0104284
f010140b:	e8 7b ec ff ff       	call   f010008b <_panic>
f0101410:	89 f0                	mov    %esi,%eax
f0101412:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101418:	c1 f8 03             	sar    $0x3,%eax
f010141b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010141e:	89 c2                	mov    %eax,%edx
f0101420:	c1 ea 0c             	shr    $0xc,%edx
f0101423:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101429:	72 12                	jb     f010143d <mem_init+0x3eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010142b:	50                   	push   %eax
f010142c:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0101431:	6a 52                	push   $0x52
f0101433:	68 90 42 10 f0       	push   $0xf0104290
f0101438:	e8 4e ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010143d:	83 ec 04             	sub    $0x4,%esp
f0101440:	68 00 10 00 00       	push   $0x1000
f0101445:	6a 01                	push   $0x1
f0101447:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010144c:	50                   	push   %eax
f010144d:	e8 15 1d 00 00       	call   f0103167 <memset>
	page_free(pp0);
f0101452:	89 34 24             	mov    %esi,(%esp)
f0101455:	e8 b3 f9 ff ff       	call   f0100e0d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010145a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101461:	e8 37 f9 ff ff       	call   f0100d9d <page_alloc>
f0101466:	83 c4 10             	add    $0x10,%esp
f0101469:	85 c0                	test   %eax,%eax
f010146b:	75 19                	jne    f0101486 <mem_init+0x434>
f010146d:	68 1c 44 10 f0       	push   $0xf010441c
f0101472:	68 aa 42 10 f0       	push   $0xf01042aa
f0101477:	68 bf 02 00 00       	push   $0x2bf
f010147c:	68 84 42 10 f0       	push   $0xf0104284
f0101481:	e8 05 ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101486:	39 c6                	cmp    %eax,%esi
f0101488:	74 19                	je     f01014a3 <mem_init+0x451>
f010148a:	68 3a 44 10 f0       	push   $0xf010443a
f010148f:	68 aa 42 10 f0       	push   $0xf01042aa
f0101494:	68 c0 02 00 00       	push   $0x2c0
f0101499:	68 84 42 10 f0       	push   $0xf0104284
f010149e:	e8 e8 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014a3:	89 f0                	mov    %esi,%eax
f01014a5:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01014ab:	c1 f8 03             	sar    $0x3,%eax
f01014ae:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014b1:	89 c2                	mov    %eax,%edx
f01014b3:	c1 ea 0c             	shr    $0xc,%edx
f01014b6:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01014bc:	72 12                	jb     f01014d0 <mem_init+0x47e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014be:	50                   	push   %eax
f01014bf:	68 9c 3a 10 f0       	push   $0xf0103a9c
f01014c4:	6a 52                	push   $0x52
f01014c6:	68 90 42 10 f0       	push   $0xf0104290
f01014cb:	e8 bb eb ff ff       	call   f010008b <_panic>
f01014d0:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014d6:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014dc:	80 38 00             	cmpb   $0x0,(%eax)
f01014df:	74 19                	je     f01014fa <mem_init+0x4a8>
f01014e1:	68 4a 44 10 f0       	push   $0xf010444a
f01014e6:	68 aa 42 10 f0       	push   $0xf01042aa
f01014eb:	68 c3 02 00 00       	push   $0x2c3
f01014f0:	68 84 42 10 f0       	push   $0xf0104284
f01014f5:	e8 91 eb ff ff       	call   f010008b <_panic>
f01014fa:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014fd:	39 d0                	cmp    %edx,%eax
f01014ff:	75 db                	jne    f01014dc <mem_init+0x48a>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101501:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101504:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101509:	83 ec 0c             	sub    $0xc,%esp
f010150c:	56                   	push   %esi
f010150d:	e8 fb f8 ff ff       	call   f0100e0d <page_free>
	page_free(pp1);
f0101512:	89 3c 24             	mov    %edi,(%esp)
f0101515:	e8 f3 f8 ff ff       	call   f0100e0d <page_free>
	page_free(pp2);
f010151a:	83 c4 04             	add    $0x4,%esp
f010151d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101520:	e8 e8 f8 ff ff       	call   f0100e0d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101525:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010152a:	83 c4 10             	add    $0x10,%esp
f010152d:	eb 05                	jmp    f0101534 <mem_init+0x4e2>
		--nfree;
f010152f:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101532:	8b 00                	mov    (%eax),%eax
f0101534:	85 c0                	test   %eax,%eax
f0101536:	75 f7                	jne    f010152f <mem_init+0x4dd>
		--nfree;
	assert(nfree == 0);
f0101538:	85 db                	test   %ebx,%ebx
f010153a:	74 19                	je     f0101555 <mem_init+0x503>
f010153c:	68 54 44 10 f0       	push   $0xf0104454
f0101541:	68 aa 42 10 f0       	push   $0xf01042aa
f0101546:	68 d0 02 00 00       	push   $0x2d0
f010154b:	68 84 42 10 f0       	push   $0xf0104284
f0101550:	e8 36 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101555:	83 ec 0c             	sub    $0xc,%esp
f0101558:	68 b8 3c 10 f0       	push   $0xf0103cb8
f010155d:	e8 9b 11 00 00       	call   f01026fd <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101562:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101569:	e8 2f f8 ff ff       	call   f0100d9d <page_alloc>
f010156e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101571:	83 c4 10             	add    $0x10,%esp
f0101574:	85 c0                	test   %eax,%eax
f0101576:	75 19                	jne    f0101591 <mem_init+0x53f>
f0101578:	68 62 43 10 f0       	push   $0xf0104362
f010157d:	68 aa 42 10 f0       	push   $0xf01042aa
f0101582:	68 29 03 00 00       	push   $0x329
f0101587:	68 84 42 10 f0       	push   $0xf0104284
f010158c:	e8 fa ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101591:	83 ec 0c             	sub    $0xc,%esp
f0101594:	6a 00                	push   $0x0
f0101596:	e8 02 f8 ff ff       	call   f0100d9d <page_alloc>
f010159b:	89 c3                	mov    %eax,%ebx
f010159d:	83 c4 10             	add    $0x10,%esp
f01015a0:	85 c0                	test   %eax,%eax
f01015a2:	75 19                	jne    f01015bd <mem_init+0x56b>
f01015a4:	68 78 43 10 f0       	push   $0xf0104378
f01015a9:	68 aa 42 10 f0       	push   $0xf01042aa
f01015ae:	68 2a 03 00 00       	push   $0x32a
f01015b3:	68 84 42 10 f0       	push   $0xf0104284
f01015b8:	e8 ce ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015bd:	83 ec 0c             	sub    $0xc,%esp
f01015c0:	6a 00                	push   $0x0
f01015c2:	e8 d6 f7 ff ff       	call   f0100d9d <page_alloc>
f01015c7:	89 c6                	mov    %eax,%esi
f01015c9:	83 c4 10             	add    $0x10,%esp
f01015cc:	85 c0                	test   %eax,%eax
f01015ce:	75 19                	jne    f01015e9 <mem_init+0x597>
f01015d0:	68 8e 43 10 f0       	push   $0xf010438e
f01015d5:	68 aa 42 10 f0       	push   $0xf01042aa
f01015da:	68 2b 03 00 00       	push   $0x32b
f01015df:	68 84 42 10 f0       	push   $0xf0104284
f01015e4:	e8 a2 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015e9:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015ec:	75 19                	jne    f0101607 <mem_init+0x5b5>
f01015ee:	68 a4 43 10 f0       	push   $0xf01043a4
f01015f3:	68 aa 42 10 f0       	push   $0xf01042aa
f01015f8:	68 2e 03 00 00       	push   $0x32e
f01015fd:	68 84 42 10 f0       	push   $0xf0104284
f0101602:	e8 84 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101607:	39 c3                	cmp    %eax,%ebx
f0101609:	74 05                	je     f0101610 <mem_init+0x5be>
f010160b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010160e:	75 19                	jne    f0101629 <mem_init+0x5d7>
f0101610:	68 98 3c 10 f0       	push   $0xf0103c98
f0101615:	68 aa 42 10 f0       	push   $0xf01042aa
f010161a:	68 2f 03 00 00       	push   $0x32f
f010161f:	68 84 42 10 f0       	push   $0xf0104284
f0101624:	e8 62 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101629:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010162e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101631:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101638:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010163b:	83 ec 0c             	sub    $0xc,%esp
f010163e:	6a 00                	push   $0x0
f0101640:	e8 58 f7 ff ff       	call   f0100d9d <page_alloc>
f0101645:	83 c4 10             	add    $0x10,%esp
f0101648:	85 c0                	test   %eax,%eax
f010164a:	74 19                	je     f0101665 <mem_init+0x613>
f010164c:	68 0d 44 10 f0       	push   $0xf010440d
f0101651:	68 aa 42 10 f0       	push   $0xf01042aa
f0101656:	68 36 03 00 00       	push   $0x336
f010165b:	68 84 42 10 f0       	push   $0xf0104284
f0101660:	e8 26 ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101665:	83 ec 04             	sub    $0x4,%esp
f0101668:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010166b:	50                   	push   %eax
f010166c:	6a 00                	push   $0x0
f010166e:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101674:	e8 dd f8 ff ff       	call   f0100f56 <page_lookup>
f0101679:	83 c4 10             	add    $0x10,%esp
f010167c:	85 c0                	test   %eax,%eax
f010167e:	74 19                	je     f0101699 <mem_init+0x647>
f0101680:	68 d8 3c 10 f0       	push   $0xf0103cd8
f0101685:	68 aa 42 10 f0       	push   $0xf01042aa
f010168a:	68 39 03 00 00       	push   $0x339
f010168f:	68 84 42 10 f0       	push   $0xf0104284
f0101694:	e8 f2 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101699:	6a 02                	push   $0x2
f010169b:	6a 00                	push   $0x0
f010169d:	53                   	push   %ebx
f010169e:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016a4:	e8 42 f9 ff ff       	call   f0100feb <page_insert>
f01016a9:	83 c4 10             	add    $0x10,%esp
f01016ac:	85 c0                	test   %eax,%eax
f01016ae:	78 19                	js     f01016c9 <mem_init+0x677>
f01016b0:	68 10 3d 10 f0       	push   $0xf0103d10
f01016b5:	68 aa 42 10 f0       	push   $0xf01042aa
f01016ba:	68 3c 03 00 00       	push   $0x33c
f01016bf:	68 84 42 10 f0       	push   $0xf0104284
f01016c4:	e8 c2 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016c9:	83 ec 0c             	sub    $0xc,%esp
f01016cc:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016cf:	e8 39 f7 ff ff       	call   f0100e0d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016d4:	6a 02                	push   $0x2
f01016d6:	6a 00                	push   $0x0
f01016d8:	53                   	push   %ebx
f01016d9:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016df:	e8 07 f9 ff ff       	call   f0100feb <page_insert>
f01016e4:	83 c4 20             	add    $0x20,%esp
f01016e7:	85 c0                	test   %eax,%eax
f01016e9:	74 19                	je     f0101704 <mem_init+0x6b2>
f01016eb:	68 40 3d 10 f0       	push   $0xf0103d40
f01016f0:	68 aa 42 10 f0       	push   $0xf01042aa
f01016f5:	68 40 03 00 00       	push   $0x340
f01016fa:	68 84 42 10 f0       	push   $0xf0104284
f01016ff:	e8 87 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101704:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010170a:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f010170f:	89 c1                	mov    %eax,%ecx
f0101711:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101714:	8b 17                	mov    (%edi),%edx
f0101716:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010171c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010171f:	29 c8                	sub    %ecx,%eax
f0101721:	c1 f8 03             	sar    $0x3,%eax
f0101724:	c1 e0 0c             	shl    $0xc,%eax
f0101727:	39 c2                	cmp    %eax,%edx
f0101729:	74 19                	je     f0101744 <mem_init+0x6f2>
f010172b:	68 70 3d 10 f0       	push   $0xf0103d70
f0101730:	68 aa 42 10 f0       	push   $0xf01042aa
f0101735:	68 41 03 00 00       	push   $0x341
f010173a:	68 84 42 10 f0       	push   $0xf0104284
f010173f:	e8 47 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101744:	ba 00 00 00 00       	mov    $0x0,%edx
f0101749:	89 f8                	mov    %edi,%eax
f010174b:	e8 3d f1 ff ff       	call   f010088d <check_va2pa>
f0101750:	89 da                	mov    %ebx,%edx
f0101752:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101755:	c1 fa 03             	sar    $0x3,%edx
f0101758:	c1 e2 0c             	shl    $0xc,%edx
f010175b:	39 d0                	cmp    %edx,%eax
f010175d:	74 19                	je     f0101778 <mem_init+0x726>
f010175f:	68 98 3d 10 f0       	push   $0xf0103d98
f0101764:	68 aa 42 10 f0       	push   $0xf01042aa
f0101769:	68 42 03 00 00       	push   $0x342
f010176e:	68 84 42 10 f0       	push   $0xf0104284
f0101773:	e8 13 e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101778:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010177d:	74 19                	je     f0101798 <mem_init+0x746>
f010177f:	68 5f 44 10 f0       	push   $0xf010445f
f0101784:	68 aa 42 10 f0       	push   $0xf01042aa
f0101789:	68 43 03 00 00       	push   $0x343
f010178e:	68 84 42 10 f0       	push   $0xf0104284
f0101793:	e8 f3 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101798:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010179b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017a0:	74 19                	je     f01017bb <mem_init+0x769>
f01017a2:	68 70 44 10 f0       	push   $0xf0104470
f01017a7:	68 aa 42 10 f0       	push   $0xf01042aa
f01017ac:	68 44 03 00 00       	push   $0x344
f01017b1:	68 84 42 10 f0       	push   $0xf0104284
f01017b6:	e8 d0 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017bb:	6a 02                	push   $0x2
f01017bd:	68 00 10 00 00       	push   $0x1000
f01017c2:	56                   	push   %esi
f01017c3:	57                   	push   %edi
f01017c4:	e8 22 f8 ff ff       	call   f0100feb <page_insert>
f01017c9:	83 c4 10             	add    $0x10,%esp
f01017cc:	85 c0                	test   %eax,%eax
f01017ce:	74 19                	je     f01017e9 <mem_init+0x797>
f01017d0:	68 c8 3d 10 f0       	push   $0xf0103dc8
f01017d5:	68 aa 42 10 f0       	push   $0xf01042aa
f01017da:	68 47 03 00 00       	push   $0x347
f01017df:	68 84 42 10 f0       	push   $0xf0104284
f01017e4:	e8 a2 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017e9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017ee:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01017f3:	e8 95 f0 ff ff       	call   f010088d <check_va2pa>
f01017f8:	89 f2                	mov    %esi,%edx
f01017fa:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101800:	c1 fa 03             	sar    $0x3,%edx
f0101803:	c1 e2 0c             	shl    $0xc,%edx
f0101806:	39 d0                	cmp    %edx,%eax
f0101808:	74 19                	je     f0101823 <mem_init+0x7d1>
f010180a:	68 04 3e 10 f0       	push   $0xf0103e04
f010180f:	68 aa 42 10 f0       	push   $0xf01042aa
f0101814:	68 48 03 00 00       	push   $0x348
f0101819:	68 84 42 10 f0       	push   $0xf0104284
f010181e:	e8 68 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101823:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101828:	74 19                	je     f0101843 <mem_init+0x7f1>
f010182a:	68 81 44 10 f0       	push   $0xf0104481
f010182f:	68 aa 42 10 f0       	push   $0xf01042aa
f0101834:	68 49 03 00 00       	push   $0x349
f0101839:	68 84 42 10 f0       	push   $0xf0104284
f010183e:	e8 48 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101843:	83 ec 0c             	sub    $0xc,%esp
f0101846:	6a 00                	push   $0x0
f0101848:	e8 50 f5 ff ff       	call   f0100d9d <page_alloc>
f010184d:	83 c4 10             	add    $0x10,%esp
f0101850:	85 c0                	test   %eax,%eax
f0101852:	74 19                	je     f010186d <mem_init+0x81b>
f0101854:	68 0d 44 10 f0       	push   $0xf010440d
f0101859:	68 aa 42 10 f0       	push   $0xf01042aa
f010185e:	68 4c 03 00 00       	push   $0x34c
f0101863:	68 84 42 10 f0       	push   $0xf0104284
f0101868:	e8 1e e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010186d:	6a 02                	push   $0x2
f010186f:	68 00 10 00 00       	push   $0x1000
f0101874:	56                   	push   %esi
f0101875:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010187b:	e8 6b f7 ff ff       	call   f0100feb <page_insert>
f0101880:	83 c4 10             	add    $0x10,%esp
f0101883:	85 c0                	test   %eax,%eax
f0101885:	74 19                	je     f01018a0 <mem_init+0x84e>
f0101887:	68 c8 3d 10 f0       	push   $0xf0103dc8
f010188c:	68 aa 42 10 f0       	push   $0xf01042aa
f0101891:	68 4f 03 00 00       	push   $0x34f
f0101896:	68 84 42 10 f0       	push   $0xf0104284
f010189b:	e8 eb e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018a0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018a5:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01018aa:	e8 de ef ff ff       	call   f010088d <check_va2pa>
f01018af:	89 f2                	mov    %esi,%edx
f01018b1:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01018b7:	c1 fa 03             	sar    $0x3,%edx
f01018ba:	c1 e2 0c             	shl    $0xc,%edx
f01018bd:	39 d0                	cmp    %edx,%eax
f01018bf:	74 19                	je     f01018da <mem_init+0x888>
f01018c1:	68 04 3e 10 f0       	push   $0xf0103e04
f01018c6:	68 aa 42 10 f0       	push   $0xf01042aa
f01018cb:	68 50 03 00 00       	push   $0x350
f01018d0:	68 84 42 10 f0       	push   $0xf0104284
f01018d5:	e8 b1 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018da:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018df:	74 19                	je     f01018fa <mem_init+0x8a8>
f01018e1:	68 81 44 10 f0       	push   $0xf0104481
f01018e6:	68 aa 42 10 f0       	push   $0xf01042aa
f01018eb:	68 51 03 00 00       	push   $0x351
f01018f0:	68 84 42 10 f0       	push   $0xf0104284
f01018f5:	e8 91 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018fa:	83 ec 0c             	sub    $0xc,%esp
f01018fd:	6a 00                	push   $0x0
f01018ff:	e8 99 f4 ff ff       	call   f0100d9d <page_alloc>
f0101904:	83 c4 10             	add    $0x10,%esp
f0101907:	85 c0                	test   %eax,%eax
f0101909:	74 19                	je     f0101924 <mem_init+0x8d2>
f010190b:	68 0d 44 10 f0       	push   $0xf010440d
f0101910:	68 aa 42 10 f0       	push   $0xf01042aa
f0101915:	68 55 03 00 00       	push   $0x355
f010191a:	68 84 42 10 f0       	push   $0xf0104284
f010191f:	e8 67 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101924:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f010192a:	8b 02                	mov    (%edx),%eax
f010192c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101931:	89 c1                	mov    %eax,%ecx
f0101933:	c1 e9 0c             	shr    $0xc,%ecx
f0101936:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f010193c:	72 15                	jb     f0101953 <mem_init+0x901>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010193e:	50                   	push   %eax
f010193f:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0101944:	68 58 03 00 00       	push   $0x358
f0101949:	68 84 42 10 f0       	push   $0xf0104284
f010194e:	e8 38 e7 ff ff       	call   f010008b <_panic>
f0101953:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101958:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010195b:	83 ec 04             	sub    $0x4,%esp
f010195e:	6a 00                	push   $0x0
f0101960:	68 00 10 00 00       	push   $0x1000
f0101965:	52                   	push   %edx
f0101966:	e8 04 f5 ff ff       	call   f0100e6f <pgdir_walk>
f010196b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010196e:	8d 51 04             	lea    0x4(%ecx),%edx
f0101971:	83 c4 10             	add    $0x10,%esp
f0101974:	39 d0                	cmp    %edx,%eax
f0101976:	74 19                	je     f0101991 <mem_init+0x93f>
f0101978:	68 34 3e 10 f0       	push   $0xf0103e34
f010197d:	68 aa 42 10 f0       	push   $0xf01042aa
f0101982:	68 59 03 00 00       	push   $0x359
f0101987:	68 84 42 10 f0       	push   $0xf0104284
f010198c:	e8 fa e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101991:	6a 06                	push   $0x6
f0101993:	68 00 10 00 00       	push   $0x1000
f0101998:	56                   	push   %esi
f0101999:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010199f:	e8 47 f6 ff ff       	call   f0100feb <page_insert>
f01019a4:	83 c4 10             	add    $0x10,%esp
f01019a7:	85 c0                	test   %eax,%eax
f01019a9:	74 19                	je     f01019c4 <mem_init+0x972>
f01019ab:	68 74 3e 10 f0       	push   $0xf0103e74
f01019b0:	68 aa 42 10 f0       	push   $0xf01042aa
f01019b5:	68 5c 03 00 00       	push   $0x35c
f01019ba:	68 84 42 10 f0       	push   $0xf0104284
f01019bf:	e8 c7 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019c4:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01019ca:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019cf:	89 f8                	mov    %edi,%eax
f01019d1:	e8 b7 ee ff ff       	call   f010088d <check_va2pa>
f01019d6:	89 f2                	mov    %esi,%edx
f01019d8:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019de:	c1 fa 03             	sar    $0x3,%edx
f01019e1:	c1 e2 0c             	shl    $0xc,%edx
f01019e4:	39 d0                	cmp    %edx,%eax
f01019e6:	74 19                	je     f0101a01 <mem_init+0x9af>
f01019e8:	68 04 3e 10 f0       	push   $0xf0103e04
f01019ed:	68 aa 42 10 f0       	push   $0xf01042aa
f01019f2:	68 5d 03 00 00       	push   $0x35d
f01019f7:	68 84 42 10 f0       	push   $0xf0104284
f01019fc:	e8 8a e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a01:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a06:	74 19                	je     f0101a21 <mem_init+0x9cf>
f0101a08:	68 81 44 10 f0       	push   $0xf0104481
f0101a0d:	68 aa 42 10 f0       	push   $0xf01042aa
f0101a12:	68 5e 03 00 00       	push   $0x35e
f0101a17:	68 84 42 10 f0       	push   $0xf0104284
f0101a1c:	e8 6a e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a21:	83 ec 04             	sub    $0x4,%esp
f0101a24:	6a 00                	push   $0x0
f0101a26:	68 00 10 00 00       	push   $0x1000
f0101a2b:	57                   	push   %edi
f0101a2c:	e8 3e f4 ff ff       	call   f0100e6f <pgdir_walk>
f0101a31:	83 c4 10             	add    $0x10,%esp
f0101a34:	f6 00 04             	testb  $0x4,(%eax)
f0101a37:	75 19                	jne    f0101a52 <mem_init+0xa00>
f0101a39:	68 b4 3e 10 f0       	push   $0xf0103eb4
f0101a3e:	68 aa 42 10 f0       	push   $0xf01042aa
f0101a43:	68 5f 03 00 00       	push   $0x35f
f0101a48:	68 84 42 10 f0       	push   $0xf0104284
f0101a4d:	e8 39 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a52:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a57:	f6 00 04             	testb  $0x4,(%eax)
f0101a5a:	75 19                	jne    f0101a75 <mem_init+0xa23>
f0101a5c:	68 92 44 10 f0       	push   $0xf0104492
f0101a61:	68 aa 42 10 f0       	push   $0xf01042aa
f0101a66:	68 60 03 00 00       	push   $0x360
f0101a6b:	68 84 42 10 f0       	push   $0xf0104284
f0101a70:	e8 16 e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a75:	6a 02                	push   $0x2
f0101a77:	68 00 10 00 00       	push   $0x1000
f0101a7c:	56                   	push   %esi
f0101a7d:	50                   	push   %eax
f0101a7e:	e8 68 f5 ff ff       	call   f0100feb <page_insert>
f0101a83:	83 c4 10             	add    $0x10,%esp
f0101a86:	85 c0                	test   %eax,%eax
f0101a88:	74 19                	je     f0101aa3 <mem_init+0xa51>
f0101a8a:	68 c8 3d 10 f0       	push   $0xf0103dc8
f0101a8f:	68 aa 42 10 f0       	push   $0xf01042aa
f0101a94:	68 63 03 00 00       	push   $0x363
f0101a99:	68 84 42 10 f0       	push   $0xf0104284
f0101a9e:	e8 e8 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101aa3:	83 ec 04             	sub    $0x4,%esp
f0101aa6:	6a 00                	push   $0x0
f0101aa8:	68 00 10 00 00       	push   $0x1000
f0101aad:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ab3:	e8 b7 f3 ff ff       	call   f0100e6f <pgdir_walk>
f0101ab8:	83 c4 10             	add    $0x10,%esp
f0101abb:	f6 00 02             	testb  $0x2,(%eax)
f0101abe:	75 19                	jne    f0101ad9 <mem_init+0xa87>
f0101ac0:	68 e8 3e 10 f0       	push   $0xf0103ee8
f0101ac5:	68 aa 42 10 f0       	push   $0xf01042aa
f0101aca:	68 64 03 00 00       	push   $0x364
f0101acf:	68 84 42 10 f0       	push   $0xf0104284
f0101ad4:	e8 b2 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ad9:	83 ec 04             	sub    $0x4,%esp
f0101adc:	6a 00                	push   $0x0
f0101ade:	68 00 10 00 00       	push   $0x1000
f0101ae3:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ae9:	e8 81 f3 ff ff       	call   f0100e6f <pgdir_walk>
f0101aee:	83 c4 10             	add    $0x10,%esp
f0101af1:	f6 00 04             	testb  $0x4,(%eax)
f0101af4:	74 19                	je     f0101b0f <mem_init+0xabd>
f0101af6:	68 1c 3f 10 f0       	push   $0xf0103f1c
f0101afb:	68 aa 42 10 f0       	push   $0xf01042aa
f0101b00:	68 65 03 00 00       	push   $0x365
f0101b05:	68 84 42 10 f0       	push   $0xf0104284
f0101b0a:	e8 7c e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b0f:	6a 02                	push   $0x2
f0101b11:	68 00 00 40 00       	push   $0x400000
f0101b16:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b19:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b1f:	e8 c7 f4 ff ff       	call   f0100feb <page_insert>
f0101b24:	83 c4 10             	add    $0x10,%esp
f0101b27:	85 c0                	test   %eax,%eax
f0101b29:	78 19                	js     f0101b44 <mem_init+0xaf2>
f0101b2b:	68 54 3f 10 f0       	push   $0xf0103f54
f0101b30:	68 aa 42 10 f0       	push   $0xf01042aa
f0101b35:	68 68 03 00 00       	push   $0x368
f0101b3a:	68 84 42 10 f0       	push   $0xf0104284
f0101b3f:	e8 47 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b44:	6a 02                	push   $0x2
f0101b46:	68 00 10 00 00       	push   $0x1000
f0101b4b:	53                   	push   %ebx
f0101b4c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b52:	e8 94 f4 ff ff       	call   f0100feb <page_insert>
f0101b57:	83 c4 10             	add    $0x10,%esp
f0101b5a:	85 c0                	test   %eax,%eax
f0101b5c:	74 19                	je     f0101b77 <mem_init+0xb25>
f0101b5e:	68 8c 3f 10 f0       	push   $0xf0103f8c
f0101b63:	68 aa 42 10 f0       	push   $0xf01042aa
f0101b68:	68 6b 03 00 00       	push   $0x36b
f0101b6d:	68 84 42 10 f0       	push   $0xf0104284
f0101b72:	e8 14 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b77:	83 ec 04             	sub    $0x4,%esp
f0101b7a:	6a 00                	push   $0x0
f0101b7c:	68 00 10 00 00       	push   $0x1000
f0101b81:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b87:	e8 e3 f2 ff ff       	call   f0100e6f <pgdir_walk>
f0101b8c:	83 c4 10             	add    $0x10,%esp
f0101b8f:	f6 00 04             	testb  $0x4,(%eax)
f0101b92:	74 19                	je     f0101bad <mem_init+0xb5b>
f0101b94:	68 1c 3f 10 f0       	push   $0xf0103f1c
f0101b99:	68 aa 42 10 f0       	push   $0xf01042aa
f0101b9e:	68 6c 03 00 00       	push   $0x36c
f0101ba3:	68 84 42 10 f0       	push   $0xf0104284
f0101ba8:	e8 de e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bad:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101bb3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bb8:	89 f8                	mov    %edi,%eax
f0101bba:	e8 ce ec ff ff       	call   f010088d <check_va2pa>
f0101bbf:	89 c1                	mov    %eax,%ecx
f0101bc1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bc4:	89 d8                	mov    %ebx,%eax
f0101bc6:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101bcc:	c1 f8 03             	sar    $0x3,%eax
f0101bcf:	c1 e0 0c             	shl    $0xc,%eax
f0101bd2:	39 c1                	cmp    %eax,%ecx
f0101bd4:	74 19                	je     f0101bef <mem_init+0xb9d>
f0101bd6:	68 c8 3f 10 f0       	push   $0xf0103fc8
f0101bdb:	68 aa 42 10 f0       	push   $0xf01042aa
f0101be0:	68 6f 03 00 00       	push   $0x36f
f0101be5:	68 84 42 10 f0       	push   $0xf0104284
f0101bea:	e8 9c e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101bef:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bf4:	89 f8                	mov    %edi,%eax
f0101bf6:	e8 92 ec ff ff       	call   f010088d <check_va2pa>
f0101bfb:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bfe:	74 19                	je     f0101c19 <mem_init+0xbc7>
f0101c00:	68 f4 3f 10 f0       	push   $0xf0103ff4
f0101c05:	68 aa 42 10 f0       	push   $0xf01042aa
f0101c0a:	68 70 03 00 00       	push   $0x370
f0101c0f:	68 84 42 10 f0       	push   $0xf0104284
f0101c14:	e8 72 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c19:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c1e:	74 19                	je     f0101c39 <mem_init+0xbe7>
f0101c20:	68 a8 44 10 f0       	push   $0xf01044a8
f0101c25:	68 aa 42 10 f0       	push   $0xf01042aa
f0101c2a:	68 72 03 00 00       	push   $0x372
f0101c2f:	68 84 42 10 f0       	push   $0xf0104284
f0101c34:	e8 52 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c39:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c3e:	74 19                	je     f0101c59 <mem_init+0xc07>
f0101c40:	68 b9 44 10 f0       	push   $0xf01044b9
f0101c45:	68 aa 42 10 f0       	push   $0xf01042aa
f0101c4a:	68 73 03 00 00       	push   $0x373
f0101c4f:	68 84 42 10 f0       	push   $0xf0104284
f0101c54:	e8 32 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c59:	83 ec 0c             	sub    $0xc,%esp
f0101c5c:	6a 00                	push   $0x0
f0101c5e:	e8 3a f1 ff ff       	call   f0100d9d <page_alloc>
f0101c63:	83 c4 10             	add    $0x10,%esp
f0101c66:	85 c0                	test   %eax,%eax
f0101c68:	74 04                	je     f0101c6e <mem_init+0xc1c>
f0101c6a:	39 c6                	cmp    %eax,%esi
f0101c6c:	74 19                	je     f0101c87 <mem_init+0xc35>
f0101c6e:	68 24 40 10 f0       	push   $0xf0104024
f0101c73:	68 aa 42 10 f0       	push   $0xf01042aa
f0101c78:	68 76 03 00 00       	push   $0x376
f0101c7d:	68 84 42 10 f0       	push   $0xf0104284
f0101c82:	e8 04 e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c87:	83 ec 08             	sub    $0x8,%esp
f0101c8a:	6a 00                	push   $0x0
f0101c8c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101c92:	e8 19 f3 ff ff       	call   f0100fb0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c97:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c9d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ca2:	89 f8                	mov    %edi,%eax
f0101ca4:	e8 e4 eb ff ff       	call   f010088d <check_va2pa>
f0101ca9:	83 c4 10             	add    $0x10,%esp
f0101cac:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101caf:	74 19                	je     f0101cca <mem_init+0xc78>
f0101cb1:	68 48 40 10 f0       	push   $0xf0104048
f0101cb6:	68 aa 42 10 f0       	push   $0xf01042aa
f0101cbb:	68 7a 03 00 00       	push   $0x37a
f0101cc0:	68 84 42 10 f0       	push   $0xf0104284
f0101cc5:	e8 c1 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cca:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ccf:	89 f8                	mov    %edi,%eax
f0101cd1:	e8 b7 eb ff ff       	call   f010088d <check_va2pa>
f0101cd6:	89 da                	mov    %ebx,%edx
f0101cd8:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101cde:	c1 fa 03             	sar    $0x3,%edx
f0101ce1:	c1 e2 0c             	shl    $0xc,%edx
f0101ce4:	39 d0                	cmp    %edx,%eax
f0101ce6:	74 19                	je     f0101d01 <mem_init+0xcaf>
f0101ce8:	68 f4 3f 10 f0       	push   $0xf0103ff4
f0101ced:	68 aa 42 10 f0       	push   $0xf01042aa
f0101cf2:	68 7b 03 00 00       	push   $0x37b
f0101cf7:	68 84 42 10 f0       	push   $0xf0104284
f0101cfc:	e8 8a e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d01:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d06:	74 19                	je     f0101d21 <mem_init+0xccf>
f0101d08:	68 5f 44 10 f0       	push   $0xf010445f
f0101d0d:	68 aa 42 10 f0       	push   $0xf01042aa
f0101d12:	68 7c 03 00 00       	push   $0x37c
f0101d17:	68 84 42 10 f0       	push   $0xf0104284
f0101d1c:	e8 6a e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d21:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d26:	74 19                	je     f0101d41 <mem_init+0xcef>
f0101d28:	68 b9 44 10 f0       	push   $0xf01044b9
f0101d2d:	68 aa 42 10 f0       	push   $0xf01042aa
f0101d32:	68 7d 03 00 00       	push   $0x37d
f0101d37:	68 84 42 10 f0       	push   $0xf0104284
f0101d3c:	e8 4a e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d41:	6a 00                	push   $0x0
f0101d43:	68 00 10 00 00       	push   $0x1000
f0101d48:	53                   	push   %ebx
f0101d49:	57                   	push   %edi
f0101d4a:	e8 9c f2 ff ff       	call   f0100feb <page_insert>
f0101d4f:	83 c4 10             	add    $0x10,%esp
f0101d52:	85 c0                	test   %eax,%eax
f0101d54:	74 19                	je     f0101d6f <mem_init+0xd1d>
f0101d56:	68 6c 40 10 f0       	push   $0xf010406c
f0101d5b:	68 aa 42 10 f0       	push   $0xf01042aa
f0101d60:	68 80 03 00 00       	push   $0x380
f0101d65:	68 84 42 10 f0       	push   $0xf0104284
f0101d6a:	e8 1c e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d6f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d74:	75 19                	jne    f0101d8f <mem_init+0xd3d>
f0101d76:	68 ca 44 10 f0       	push   $0xf01044ca
f0101d7b:	68 aa 42 10 f0       	push   $0xf01042aa
f0101d80:	68 81 03 00 00       	push   $0x381
f0101d85:	68 84 42 10 f0       	push   $0xf0104284
f0101d8a:	e8 fc e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d8f:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d92:	74 19                	je     f0101dad <mem_init+0xd5b>
f0101d94:	68 d6 44 10 f0       	push   $0xf01044d6
f0101d99:	68 aa 42 10 f0       	push   $0xf01042aa
f0101d9e:	68 82 03 00 00       	push   $0x382
f0101da3:	68 84 42 10 f0       	push   $0xf0104284
f0101da8:	e8 de e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101dad:	83 ec 08             	sub    $0x8,%esp
f0101db0:	68 00 10 00 00       	push   $0x1000
f0101db5:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101dbb:	e8 f0 f1 ff ff       	call   f0100fb0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dc0:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101dc6:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dcb:	89 f8                	mov    %edi,%eax
f0101dcd:	e8 bb ea ff ff       	call   f010088d <check_va2pa>
f0101dd2:	83 c4 10             	add    $0x10,%esp
f0101dd5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dd8:	74 19                	je     f0101df3 <mem_init+0xda1>
f0101dda:	68 48 40 10 f0       	push   $0xf0104048
f0101ddf:	68 aa 42 10 f0       	push   $0xf01042aa
f0101de4:	68 86 03 00 00       	push   $0x386
f0101de9:	68 84 42 10 f0       	push   $0xf0104284
f0101dee:	e8 98 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101df3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101df8:	89 f8                	mov    %edi,%eax
f0101dfa:	e8 8e ea ff ff       	call   f010088d <check_va2pa>
f0101dff:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e02:	74 19                	je     f0101e1d <mem_init+0xdcb>
f0101e04:	68 a4 40 10 f0       	push   $0xf01040a4
f0101e09:	68 aa 42 10 f0       	push   $0xf01042aa
f0101e0e:	68 87 03 00 00       	push   $0x387
f0101e13:	68 84 42 10 f0       	push   $0xf0104284
f0101e18:	e8 6e e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e1d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e22:	74 19                	je     f0101e3d <mem_init+0xdeb>
f0101e24:	68 eb 44 10 f0       	push   $0xf01044eb
f0101e29:	68 aa 42 10 f0       	push   $0xf01042aa
f0101e2e:	68 88 03 00 00       	push   $0x388
f0101e33:	68 84 42 10 f0       	push   $0xf0104284
f0101e38:	e8 4e e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e3d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e42:	74 19                	je     f0101e5d <mem_init+0xe0b>
f0101e44:	68 b9 44 10 f0       	push   $0xf01044b9
f0101e49:	68 aa 42 10 f0       	push   $0xf01042aa
f0101e4e:	68 89 03 00 00       	push   $0x389
f0101e53:	68 84 42 10 f0       	push   $0xf0104284
f0101e58:	e8 2e e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e5d:	83 ec 0c             	sub    $0xc,%esp
f0101e60:	6a 00                	push   $0x0
f0101e62:	e8 36 ef ff ff       	call   f0100d9d <page_alloc>
f0101e67:	83 c4 10             	add    $0x10,%esp
f0101e6a:	39 c3                	cmp    %eax,%ebx
f0101e6c:	75 04                	jne    f0101e72 <mem_init+0xe20>
f0101e6e:	85 c0                	test   %eax,%eax
f0101e70:	75 19                	jne    f0101e8b <mem_init+0xe39>
f0101e72:	68 cc 40 10 f0       	push   $0xf01040cc
f0101e77:	68 aa 42 10 f0       	push   $0xf01042aa
f0101e7c:	68 8c 03 00 00       	push   $0x38c
f0101e81:	68 84 42 10 f0       	push   $0xf0104284
f0101e86:	e8 00 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e8b:	83 ec 0c             	sub    $0xc,%esp
f0101e8e:	6a 00                	push   $0x0
f0101e90:	e8 08 ef ff ff       	call   f0100d9d <page_alloc>
f0101e95:	83 c4 10             	add    $0x10,%esp
f0101e98:	85 c0                	test   %eax,%eax
f0101e9a:	74 19                	je     f0101eb5 <mem_init+0xe63>
f0101e9c:	68 0d 44 10 f0       	push   $0xf010440d
f0101ea1:	68 aa 42 10 f0       	push   $0xf01042aa
f0101ea6:	68 8f 03 00 00       	push   $0x38f
f0101eab:	68 84 42 10 f0       	push   $0xf0104284
f0101eb0:	e8 d6 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eb5:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101ebb:	8b 11                	mov    (%ecx),%edx
f0101ebd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ec3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ec6:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101ecc:	c1 f8 03             	sar    $0x3,%eax
f0101ecf:	c1 e0 0c             	shl    $0xc,%eax
f0101ed2:	39 c2                	cmp    %eax,%edx
f0101ed4:	74 19                	je     f0101eef <mem_init+0xe9d>
f0101ed6:	68 70 3d 10 f0       	push   $0xf0103d70
f0101edb:	68 aa 42 10 f0       	push   $0xf01042aa
f0101ee0:	68 92 03 00 00       	push   $0x392
f0101ee5:	68 84 42 10 f0       	push   $0xf0104284
f0101eea:	e8 9c e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101eef:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101ef5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101efd:	74 19                	je     f0101f18 <mem_init+0xec6>
f0101eff:	68 70 44 10 f0       	push   $0xf0104470
f0101f04:	68 aa 42 10 f0       	push   $0xf01042aa
f0101f09:	68 94 03 00 00       	push   $0x394
f0101f0e:	68 84 42 10 f0       	push   $0xf0104284
f0101f13:	e8 73 e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f18:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f1b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f21:	83 ec 0c             	sub    $0xc,%esp
f0101f24:	50                   	push   %eax
f0101f25:	e8 e3 ee ff ff       	call   f0100e0d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f2a:	83 c4 0c             	add    $0xc,%esp
f0101f2d:	6a 01                	push   $0x1
f0101f2f:	68 00 10 40 00       	push   $0x401000
f0101f34:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f3a:	e8 30 ef ff ff       	call   f0100e6f <pgdir_walk>
f0101f3f:	89 c7                	mov    %eax,%edi
f0101f41:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f44:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f49:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f4c:	8b 40 04             	mov    0x4(%eax),%eax
f0101f4f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f54:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f5a:	89 c2                	mov    %eax,%edx
f0101f5c:	c1 ea 0c             	shr    $0xc,%edx
f0101f5f:	83 c4 10             	add    $0x10,%esp
f0101f62:	39 ca                	cmp    %ecx,%edx
f0101f64:	72 15                	jb     f0101f7b <mem_init+0xf29>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f66:	50                   	push   %eax
f0101f67:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0101f6c:	68 9b 03 00 00       	push   $0x39b
f0101f71:	68 84 42 10 f0       	push   $0xf0104284
f0101f76:	e8 10 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f7b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f80:	39 c7                	cmp    %eax,%edi
f0101f82:	74 19                	je     f0101f9d <mem_init+0xf4b>
f0101f84:	68 fc 44 10 f0       	push   $0xf01044fc
f0101f89:	68 aa 42 10 f0       	push   $0xf01042aa
f0101f8e:	68 9c 03 00 00       	push   $0x39c
f0101f93:	68 84 42 10 f0       	push   $0xf0104284
f0101f98:	e8 ee e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f9d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fa0:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fa7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101faa:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fb0:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101fb6:	c1 f8 03             	sar    $0x3,%eax
f0101fb9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fbc:	89 c2                	mov    %eax,%edx
f0101fbe:	c1 ea 0c             	shr    $0xc,%edx
f0101fc1:	39 d1                	cmp    %edx,%ecx
f0101fc3:	77 12                	ja     f0101fd7 <mem_init+0xf85>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fc5:	50                   	push   %eax
f0101fc6:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0101fcb:	6a 52                	push   $0x52
f0101fcd:	68 90 42 10 f0       	push   $0xf0104290
f0101fd2:	e8 b4 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fd7:	83 ec 04             	sub    $0x4,%esp
f0101fda:	68 00 10 00 00       	push   $0x1000
f0101fdf:	68 ff 00 00 00       	push   $0xff
f0101fe4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fe9:	50                   	push   %eax
f0101fea:	e8 78 11 00 00       	call   f0103167 <memset>
	page_free(pp0);
f0101fef:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101ff2:	89 3c 24             	mov    %edi,(%esp)
f0101ff5:	e8 13 ee ff ff       	call   f0100e0d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ffa:	83 c4 0c             	add    $0xc,%esp
f0101ffd:	6a 01                	push   $0x1
f0101fff:	6a 00                	push   $0x0
f0102001:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102007:	e8 63 ee ff ff       	call   f0100e6f <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010200c:	89 fa                	mov    %edi,%edx
f010200e:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0102014:	c1 fa 03             	sar    $0x3,%edx
f0102017:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010201a:	89 d0                	mov    %edx,%eax
f010201c:	c1 e8 0c             	shr    $0xc,%eax
f010201f:	83 c4 10             	add    $0x10,%esp
f0102022:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0102028:	72 12                	jb     f010203c <mem_init+0xfea>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010202a:	52                   	push   %edx
f010202b:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0102030:	6a 52                	push   $0x52
f0102032:	68 90 42 10 f0       	push   $0xf0104290
f0102037:	e8 4f e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f010203c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102042:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102045:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010204b:	f6 00 01             	testb  $0x1,(%eax)
f010204e:	74 19                	je     f0102069 <mem_init+0x1017>
f0102050:	68 14 45 10 f0       	push   $0xf0104514
f0102055:	68 aa 42 10 f0       	push   $0xf01042aa
f010205a:	68 a6 03 00 00       	push   $0x3a6
f010205f:	68 84 42 10 f0       	push   $0xf0104284
f0102064:	e8 22 e0 ff ff       	call   f010008b <_panic>
f0102069:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010206c:	39 d0                	cmp    %edx,%eax
f010206e:	75 db                	jne    f010204b <mem_init+0xff9>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102070:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102075:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010207b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010207e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102084:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102087:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f010208d:	83 ec 0c             	sub    $0xc,%esp
f0102090:	50                   	push   %eax
f0102091:	e8 77 ed ff ff       	call   f0100e0d <page_free>
	page_free(pp1);
f0102096:	89 1c 24             	mov    %ebx,(%esp)
f0102099:	e8 6f ed ff ff       	call   f0100e0d <page_free>
	page_free(pp2);
f010209e:	89 34 24             	mov    %esi,(%esp)
f01020a1:	e8 67 ed ff ff       	call   f0100e0d <page_free>

	cprintf("check_page() succeeded!\n");
f01020a6:	c7 04 24 2b 45 10 f0 	movl   $0xf010452b,(%esp)
f01020ad:	e8 4b 06 00 00       	call   f01026fd <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
  boot_map_region(kern_pgdir,UPAGES,UVPT-UPAGES,PADDR(pages),PTE_U | PTE_P);
f01020b2:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020b7:	83 c4 10             	add    $0x10,%esp
f01020ba:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020bf:	77 15                	ja     f01020d6 <mem_init+0x1084>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020c1:	50                   	push   %eax
f01020c2:	68 c0 3a 10 f0       	push   $0xf0103ac0
f01020c7:	68 cd 00 00 00       	push   $0xcd
f01020cc:	68 84 42 10 f0       	push   $0xf0104284
f01020d1:	e8 b5 df ff ff       	call   f010008b <_panic>
f01020d6:	83 ec 08             	sub    $0x8,%esp
f01020d9:	6a 05                	push   $0x5
f01020db:	05 00 00 00 10       	add    $0x10000000,%eax
f01020e0:	50                   	push   %eax
f01020e1:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020e6:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020eb:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01020f0:	e8 0f ee ff ff       	call   f0100f04 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020f5:	83 c4 10             	add    $0x10,%esp
f01020f8:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f01020fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102102:	77 15                	ja     f0102119 <mem_init+0x10c7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102104:	50                   	push   %eax
f0102105:	68 c0 3a 10 f0       	push   $0xf0103ac0
f010210a:	68 d9 00 00 00       	push   $0xd9
f010210f:	68 84 42 10 f0       	push   $0xf0104284
f0102114:	e8 72 df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
  boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W | PTE_P);
f0102119:	83 ec 08             	sub    $0x8,%esp
f010211c:	6a 03                	push   $0x3
f010211e:	68 00 c0 10 00       	push   $0x10c000
f0102123:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102128:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010212d:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102132:	e8 cd ed ff ff       	call   f0100f04 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
  boot_map_region(kern_pgdir,KERNBASE,4294967296-KERNBASE,0,PTE_W | PTE_P);
f0102137:	83 c4 08             	add    $0x8,%esp
f010213a:	6a 03                	push   $0x3
f010213c:	6a 00                	push   $0x0
f010213e:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102143:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102148:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010214d:	e8 b2 ed ff ff       	call   f0100f04 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102152:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102158:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010215d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102160:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102167:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010216c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010216f:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102175:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102178:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010217b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102180:	eb 55                	jmp    f01021d7 <mem_init+0x1185>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102182:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102188:	89 f0                	mov    %esi,%eax
f010218a:	e8 fe e6 ff ff       	call   f010088d <check_va2pa>
f010218f:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102196:	77 15                	ja     f01021ad <mem_init+0x115b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102198:	57                   	push   %edi
f0102199:	68 c0 3a 10 f0       	push   $0xf0103ac0
f010219e:	68 e8 02 00 00       	push   $0x2e8
f01021a3:	68 84 42 10 f0       	push   $0xf0104284
f01021a8:	e8 de de ff ff       	call   f010008b <_panic>
f01021ad:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01021b4:	39 c2                	cmp    %eax,%edx
f01021b6:	74 19                	je     f01021d1 <mem_init+0x117f>
f01021b8:	68 f0 40 10 f0       	push   $0xf01040f0
f01021bd:	68 aa 42 10 f0       	push   $0xf01042aa
f01021c2:	68 e8 02 00 00       	push   $0x2e8
f01021c7:	68 84 42 10 f0       	push   $0xf0104284
f01021cc:	e8 ba de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021d1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021d7:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021da:	77 a6                	ja     f0102182 <mem_init+0x1130>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021dc:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021df:	c1 e7 0c             	shl    $0xc,%edi
f01021e2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021e7:	eb 30                	jmp    f0102219 <mem_init+0x11c7>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021e9:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01021ef:	89 f0                	mov    %esi,%eax
f01021f1:	e8 97 e6 ff ff       	call   f010088d <check_va2pa>
f01021f6:	39 c3                	cmp    %eax,%ebx
f01021f8:	74 19                	je     f0102213 <mem_init+0x11c1>
f01021fa:	68 24 41 10 f0       	push   $0xf0104124
f01021ff:	68 aa 42 10 f0       	push   $0xf01042aa
f0102204:	68 ed 02 00 00       	push   $0x2ed
f0102209:	68 84 42 10 f0       	push   $0xf0104284
f010220e:	e8 78 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102213:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102219:	39 fb                	cmp    %edi,%ebx
f010221b:	72 cc                	jb     f01021e9 <mem_init+0x1197>
f010221d:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102222:	89 da                	mov    %ebx,%edx
f0102224:	89 f0                	mov    %esi,%eax
f0102226:	e8 62 e6 ff ff       	call   f010088d <check_va2pa>
f010222b:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102231:	39 c2                	cmp    %eax,%edx
f0102233:	74 19                	je     f010224e <mem_init+0x11fc>
f0102235:	68 4c 41 10 f0       	push   $0xf010414c
f010223a:	68 aa 42 10 f0       	push   $0xf01042aa
f010223f:	68 f1 02 00 00       	push   $0x2f1
f0102244:	68 84 42 10 f0       	push   $0xf0104284
f0102249:	e8 3d de ff ff       	call   f010008b <_panic>
f010224e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102254:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f010225a:	75 c6                	jne    f0102222 <mem_init+0x11d0>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010225c:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102261:	89 f0                	mov    %esi,%eax
f0102263:	e8 25 e6 ff ff       	call   f010088d <check_va2pa>
f0102268:	83 f8 ff             	cmp    $0xffffffff,%eax
f010226b:	74 51                	je     f01022be <mem_init+0x126c>
f010226d:	68 94 41 10 f0       	push   $0xf0104194
f0102272:	68 aa 42 10 f0       	push   $0xf01042aa
f0102277:	68 f2 02 00 00       	push   $0x2f2
f010227c:	68 84 42 10 f0       	push   $0xf0104284
f0102281:	e8 05 de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102286:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f010228b:	72 36                	jb     f01022c3 <mem_init+0x1271>
f010228d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102292:	76 07                	jbe    f010229b <mem_init+0x1249>
f0102294:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102299:	75 28                	jne    f01022c3 <mem_init+0x1271>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010229b:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f010229f:	0f 85 83 00 00 00    	jne    f0102328 <mem_init+0x12d6>
f01022a5:	68 44 45 10 f0       	push   $0xf0104544
f01022aa:	68 aa 42 10 f0       	push   $0xf01042aa
f01022af:	68 fa 02 00 00       	push   $0x2fa
f01022b4:	68 84 42 10 f0       	push   $0xf0104284
f01022b9:	e8 cd dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022be:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022c3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022c8:	76 3f                	jbe    f0102309 <mem_init+0x12b7>
				assert(pgdir[i] & PTE_P);
f01022ca:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022cd:	f6 c2 01             	test   $0x1,%dl
f01022d0:	75 19                	jne    f01022eb <mem_init+0x1299>
f01022d2:	68 44 45 10 f0       	push   $0xf0104544
f01022d7:	68 aa 42 10 f0       	push   $0xf01042aa
f01022dc:	68 fe 02 00 00       	push   $0x2fe
f01022e1:	68 84 42 10 f0       	push   $0xf0104284
f01022e6:	e8 a0 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01022eb:	f6 c2 02             	test   $0x2,%dl
f01022ee:	75 38                	jne    f0102328 <mem_init+0x12d6>
f01022f0:	68 55 45 10 f0       	push   $0xf0104555
f01022f5:	68 aa 42 10 f0       	push   $0xf01042aa
f01022fa:	68 ff 02 00 00       	push   $0x2ff
f01022ff:	68 84 42 10 f0       	push   $0xf0104284
f0102304:	e8 82 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102309:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010230d:	74 19                	je     f0102328 <mem_init+0x12d6>
f010230f:	68 66 45 10 f0       	push   $0xf0104566
f0102314:	68 aa 42 10 f0       	push   $0xf01042aa
f0102319:	68 01 03 00 00       	push   $0x301
f010231e:	68 84 42 10 f0       	push   $0xf0104284
f0102323:	e8 63 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102328:	83 c0 01             	add    $0x1,%eax
f010232b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102330:	0f 86 50 ff ff ff    	jbe    f0102286 <mem_init+0x1234>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102336:	83 ec 0c             	sub    $0xc,%esp
f0102339:	68 c4 41 10 f0       	push   $0xf01041c4
f010233e:	e8 ba 03 00 00       	call   f01026fd <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102343:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102348:	83 c4 10             	add    $0x10,%esp
f010234b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102350:	77 15                	ja     f0102367 <mem_init+0x1315>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102352:	50                   	push   %eax
f0102353:	68 c0 3a 10 f0       	push   $0xf0103ac0
f0102358:	68 ee 00 00 00       	push   $0xee
f010235d:	68 84 42 10 f0       	push   $0xf0104284
f0102362:	e8 24 dd ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102367:	05 00 00 00 10       	add    $0x10000000,%eax
f010236c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010236f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102374:	e8 0b e6 ff ff       	call   f0100984 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102379:	0f 20 c0             	mov    %cr0,%eax
f010237c:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010237f:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102384:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102387:	83 ec 0c             	sub    $0xc,%esp
f010238a:	6a 00                	push   $0x0
f010238c:	e8 0c ea ff ff       	call   f0100d9d <page_alloc>
f0102391:	89 c3                	mov    %eax,%ebx
f0102393:	83 c4 10             	add    $0x10,%esp
f0102396:	85 c0                	test   %eax,%eax
f0102398:	75 19                	jne    f01023b3 <mem_init+0x1361>
f010239a:	68 62 43 10 f0       	push   $0xf0104362
f010239f:	68 aa 42 10 f0       	push   $0xf01042aa
f01023a4:	68 c1 03 00 00       	push   $0x3c1
f01023a9:	68 84 42 10 f0       	push   $0xf0104284
f01023ae:	e8 d8 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01023b3:	83 ec 0c             	sub    $0xc,%esp
f01023b6:	6a 00                	push   $0x0
f01023b8:	e8 e0 e9 ff ff       	call   f0100d9d <page_alloc>
f01023bd:	89 c7                	mov    %eax,%edi
f01023bf:	83 c4 10             	add    $0x10,%esp
f01023c2:	85 c0                	test   %eax,%eax
f01023c4:	75 19                	jne    f01023df <mem_init+0x138d>
f01023c6:	68 78 43 10 f0       	push   $0xf0104378
f01023cb:	68 aa 42 10 f0       	push   $0xf01042aa
f01023d0:	68 c2 03 00 00       	push   $0x3c2
f01023d5:	68 84 42 10 f0       	push   $0xf0104284
f01023da:	e8 ac dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023df:	83 ec 0c             	sub    $0xc,%esp
f01023e2:	6a 00                	push   $0x0
f01023e4:	e8 b4 e9 ff ff       	call   f0100d9d <page_alloc>
f01023e9:	89 c6                	mov    %eax,%esi
f01023eb:	83 c4 10             	add    $0x10,%esp
f01023ee:	85 c0                	test   %eax,%eax
f01023f0:	75 19                	jne    f010240b <mem_init+0x13b9>
f01023f2:	68 8e 43 10 f0       	push   $0xf010438e
f01023f7:	68 aa 42 10 f0       	push   $0xf01042aa
f01023fc:	68 c3 03 00 00       	push   $0x3c3
f0102401:	68 84 42 10 f0       	push   $0xf0104284
f0102406:	e8 80 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010240b:	83 ec 0c             	sub    $0xc,%esp
f010240e:	53                   	push   %ebx
f010240f:	e8 f9 e9 ff ff       	call   f0100e0d <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102414:	89 f8                	mov    %edi,%eax
f0102416:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010241c:	c1 f8 03             	sar    $0x3,%eax
f010241f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102422:	89 c2                	mov    %eax,%edx
f0102424:	c1 ea 0c             	shr    $0xc,%edx
f0102427:	83 c4 10             	add    $0x10,%esp
f010242a:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102430:	72 12                	jb     f0102444 <mem_init+0x13f2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102432:	50                   	push   %eax
f0102433:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0102438:	6a 52                	push   $0x52
f010243a:	68 90 42 10 f0       	push   $0xf0104290
f010243f:	e8 47 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102444:	83 ec 04             	sub    $0x4,%esp
f0102447:	68 00 10 00 00       	push   $0x1000
f010244c:	6a 01                	push   $0x1
f010244e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102453:	50                   	push   %eax
f0102454:	e8 0e 0d 00 00       	call   f0103167 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102459:	89 f0                	mov    %esi,%eax
f010245b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102461:	c1 f8 03             	sar    $0x3,%eax
f0102464:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102467:	89 c2                	mov    %eax,%edx
f0102469:	c1 ea 0c             	shr    $0xc,%edx
f010246c:	83 c4 10             	add    $0x10,%esp
f010246f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102475:	72 12                	jb     f0102489 <mem_init+0x1437>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102477:	50                   	push   %eax
f0102478:	68 9c 3a 10 f0       	push   $0xf0103a9c
f010247d:	6a 52                	push   $0x52
f010247f:	68 90 42 10 f0       	push   $0xf0104290
f0102484:	e8 02 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102489:	83 ec 04             	sub    $0x4,%esp
f010248c:	68 00 10 00 00       	push   $0x1000
f0102491:	6a 02                	push   $0x2
f0102493:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102498:	50                   	push   %eax
f0102499:	e8 c9 0c 00 00       	call   f0103167 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010249e:	6a 02                	push   $0x2
f01024a0:	68 00 10 00 00       	push   $0x1000
f01024a5:	57                   	push   %edi
f01024a6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024ac:	e8 3a eb ff ff       	call   f0100feb <page_insert>
	assert(pp1->pp_ref == 1);
f01024b1:	83 c4 20             	add    $0x20,%esp
f01024b4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024b9:	74 19                	je     f01024d4 <mem_init+0x1482>
f01024bb:	68 5f 44 10 f0       	push   $0xf010445f
f01024c0:	68 aa 42 10 f0       	push   $0xf01042aa
f01024c5:	68 c8 03 00 00       	push   $0x3c8
f01024ca:	68 84 42 10 f0       	push   $0xf0104284
f01024cf:	e8 b7 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024d4:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024db:	01 01 01 
f01024de:	74 19                	je     f01024f9 <mem_init+0x14a7>
f01024e0:	68 e4 41 10 f0       	push   $0xf01041e4
f01024e5:	68 aa 42 10 f0       	push   $0xf01042aa
f01024ea:	68 c9 03 00 00       	push   $0x3c9
f01024ef:	68 84 42 10 f0       	push   $0xf0104284
f01024f4:	e8 92 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01024f9:	6a 02                	push   $0x2
f01024fb:	68 00 10 00 00       	push   $0x1000
f0102500:	56                   	push   %esi
f0102501:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102507:	e8 df ea ff ff       	call   f0100feb <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010250c:	83 c4 10             	add    $0x10,%esp
f010250f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102516:	02 02 02 
f0102519:	74 19                	je     f0102534 <mem_init+0x14e2>
f010251b:	68 08 42 10 f0       	push   $0xf0104208
f0102520:	68 aa 42 10 f0       	push   $0xf01042aa
f0102525:	68 cb 03 00 00       	push   $0x3cb
f010252a:	68 84 42 10 f0       	push   $0xf0104284
f010252f:	e8 57 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102534:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102539:	74 19                	je     f0102554 <mem_init+0x1502>
f010253b:	68 81 44 10 f0       	push   $0xf0104481
f0102540:	68 aa 42 10 f0       	push   $0xf01042aa
f0102545:	68 cc 03 00 00       	push   $0x3cc
f010254a:	68 84 42 10 f0       	push   $0xf0104284
f010254f:	e8 37 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102554:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102559:	74 19                	je     f0102574 <mem_init+0x1522>
f010255b:	68 eb 44 10 f0       	push   $0xf01044eb
f0102560:	68 aa 42 10 f0       	push   $0xf01042aa
f0102565:	68 cd 03 00 00       	push   $0x3cd
f010256a:	68 84 42 10 f0       	push   $0xf0104284
f010256f:	e8 17 db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102574:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010257b:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010257e:	89 f0                	mov    %esi,%eax
f0102580:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102586:	c1 f8 03             	sar    $0x3,%eax
f0102589:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010258c:	89 c2                	mov    %eax,%edx
f010258e:	c1 ea 0c             	shr    $0xc,%edx
f0102591:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102597:	72 12                	jb     f01025ab <mem_init+0x1559>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102599:	50                   	push   %eax
f010259a:	68 9c 3a 10 f0       	push   $0xf0103a9c
f010259f:	6a 52                	push   $0x52
f01025a1:	68 90 42 10 f0       	push   $0xf0104290
f01025a6:	e8 e0 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025ab:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025b2:	03 03 03 
f01025b5:	74 19                	je     f01025d0 <mem_init+0x157e>
f01025b7:	68 2c 42 10 f0       	push   $0xf010422c
f01025bc:	68 aa 42 10 f0       	push   $0xf01042aa
f01025c1:	68 cf 03 00 00       	push   $0x3cf
f01025c6:	68 84 42 10 f0       	push   $0xf0104284
f01025cb:	e8 bb da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025d0:	83 ec 08             	sub    $0x8,%esp
f01025d3:	68 00 10 00 00       	push   $0x1000
f01025d8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01025de:	e8 cd e9 ff ff       	call   f0100fb0 <page_remove>
	assert(pp2->pp_ref == 0);
f01025e3:	83 c4 10             	add    $0x10,%esp
f01025e6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025eb:	74 19                	je     f0102606 <mem_init+0x15b4>
f01025ed:	68 b9 44 10 f0       	push   $0xf01044b9
f01025f2:	68 aa 42 10 f0       	push   $0xf01042aa
f01025f7:	68 d1 03 00 00       	push   $0x3d1
f01025fc:	68 84 42 10 f0       	push   $0xf0104284
f0102601:	e8 85 da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102606:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f010260c:	8b 11                	mov    (%ecx),%edx
f010260e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102614:	89 d8                	mov    %ebx,%eax
f0102616:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010261c:	c1 f8 03             	sar    $0x3,%eax
f010261f:	c1 e0 0c             	shl    $0xc,%eax
f0102622:	39 c2                	cmp    %eax,%edx
f0102624:	74 19                	je     f010263f <mem_init+0x15ed>
f0102626:	68 70 3d 10 f0       	push   $0xf0103d70
f010262b:	68 aa 42 10 f0       	push   $0xf01042aa
f0102630:	68 d4 03 00 00       	push   $0x3d4
f0102635:	68 84 42 10 f0       	push   $0xf0104284
f010263a:	e8 4c da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010263f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102645:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010264a:	74 19                	je     f0102665 <mem_init+0x1613>
f010264c:	68 70 44 10 f0       	push   $0xf0104470
f0102651:	68 aa 42 10 f0       	push   $0xf01042aa
f0102656:	68 d6 03 00 00       	push   $0x3d6
f010265b:	68 84 42 10 f0       	push   $0xf0104284
f0102660:	e8 26 da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102665:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010266b:	83 ec 0c             	sub    $0xc,%esp
f010266e:	53                   	push   %ebx
f010266f:	e8 99 e7 ff ff       	call   f0100e0d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102674:	c7 04 24 58 42 10 f0 	movl   $0xf0104258,(%esp)
f010267b:	e8 7d 00 00 00       	call   f01026fd <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102680:	83 c4 10             	add    $0x10,%esp
f0102683:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102686:	5b                   	pop    %ebx
f0102687:	5e                   	pop    %esi
f0102688:	5f                   	pop    %edi
f0102689:	5d                   	pop    %ebp
f010268a:	c3                   	ret    

f010268b <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010268b:	55                   	push   %ebp
f010268c:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010268e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102691:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102694:	5d                   	pop    %ebp
f0102695:	c3                   	ret    

f0102696 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102696:	55                   	push   %ebp
f0102697:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102699:	ba 70 00 00 00       	mov    $0x70,%edx
f010269e:	8b 45 08             	mov    0x8(%ebp),%eax
f01026a1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026a2:	ba 71 00 00 00       	mov    $0x71,%edx
f01026a7:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01026a8:	0f b6 c0             	movzbl %al,%eax
}
f01026ab:	5d                   	pop    %ebp
f01026ac:	c3                   	ret    

f01026ad <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026ad:	55                   	push   %ebp
f01026ae:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026b0:	ba 70 00 00 00       	mov    $0x70,%edx
f01026b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01026b8:	ee                   	out    %al,(%dx)
f01026b9:	ba 71 00 00 00       	mov    $0x71,%edx
f01026be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026c1:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026c2:	5d                   	pop    %ebp
f01026c3:	c3                   	ret    

f01026c4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026c4:	55                   	push   %ebp
f01026c5:	89 e5                	mov    %esp,%ebp
f01026c7:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026ca:	ff 75 08             	pushl  0x8(%ebp)
f01026cd:	e8 2e df ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01026d2:	83 c4 10             	add    $0x10,%esp
f01026d5:	c9                   	leave  
f01026d6:	c3                   	ret    

f01026d7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026d7:	55                   	push   %ebp
f01026d8:	89 e5                	mov    %esp,%ebp
f01026da:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026dd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026e4:	ff 75 0c             	pushl  0xc(%ebp)
f01026e7:	ff 75 08             	pushl  0x8(%ebp)
f01026ea:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026ed:	50                   	push   %eax
f01026ee:	68 c4 26 10 f0       	push   $0xf01026c4
f01026f3:	e8 03 04 00 00       	call   f0102afb <vprintfmt>
	return cnt;
}
f01026f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026fb:	c9                   	leave  
f01026fc:	c3                   	ret    

f01026fd <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026fd:	55                   	push   %ebp
f01026fe:	89 e5                	mov    %esp,%ebp
f0102700:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102703:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102706:	50                   	push   %eax
f0102707:	ff 75 08             	pushl  0x8(%ebp)
f010270a:	e8 c8 ff ff ff       	call   f01026d7 <vcprintf>
	va_end(ap);

	return cnt;
}
f010270f:	c9                   	leave  
f0102710:	c3                   	ret    

f0102711 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102711:	55                   	push   %ebp
f0102712:	89 e5                	mov    %esp,%ebp
f0102714:	57                   	push   %edi
f0102715:	56                   	push   %esi
f0102716:	53                   	push   %ebx
f0102717:	83 ec 14             	sub    $0x14,%esp
f010271a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010271d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102720:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102723:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102726:	8b 1a                	mov    (%edx),%ebx
f0102728:	8b 01                	mov    (%ecx),%eax
f010272a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010272d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102734:	eb 7f                	jmp    f01027b5 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102736:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102739:	01 d8                	add    %ebx,%eax
f010273b:	89 c6                	mov    %eax,%esi
f010273d:	c1 ee 1f             	shr    $0x1f,%esi
f0102740:	01 c6                	add    %eax,%esi
f0102742:	d1 fe                	sar    %esi
f0102744:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102747:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010274a:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010274d:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010274f:	eb 03                	jmp    f0102754 <stab_binsearch+0x43>
			m--;
f0102751:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102754:	39 c3                	cmp    %eax,%ebx
f0102756:	7f 0d                	jg     f0102765 <stab_binsearch+0x54>
f0102758:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010275c:	83 ea 0c             	sub    $0xc,%edx
f010275f:	39 f9                	cmp    %edi,%ecx
f0102761:	75 ee                	jne    f0102751 <stab_binsearch+0x40>
f0102763:	eb 05                	jmp    f010276a <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102765:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102768:	eb 4b                	jmp    f01027b5 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010276a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010276d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102770:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102774:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102777:	76 11                	jbe    f010278a <stab_binsearch+0x79>
			*region_left = m;
f0102779:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010277c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010277e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102781:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102788:	eb 2b                	jmp    f01027b5 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010278a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010278d:	73 14                	jae    f01027a3 <stab_binsearch+0x92>
			*region_right = m - 1;
f010278f:	83 e8 01             	sub    $0x1,%eax
f0102792:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102795:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102798:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010279a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027a1:	eb 12                	jmp    f01027b5 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01027a3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027a6:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01027a8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027ac:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027ae:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027b5:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027b8:	0f 8e 78 ff ff ff    	jle    f0102736 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027be:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027c2:	75 0f                	jne    f01027d3 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027c7:	8b 00                	mov    (%eax),%eax
f01027c9:	83 e8 01             	sub    $0x1,%eax
f01027cc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027cf:	89 06                	mov    %eax,(%esi)
f01027d1:	eb 2c                	jmp    f01027ff <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027d6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027d8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027db:	8b 0e                	mov    (%esi),%ecx
f01027dd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027e0:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027e3:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027e6:	eb 03                	jmp    f01027eb <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027e8:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027eb:	39 c8                	cmp    %ecx,%eax
f01027ed:	7e 0b                	jle    f01027fa <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027ef:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027f3:	83 ea 0c             	sub    $0xc,%edx
f01027f6:	39 df                	cmp    %ebx,%edi
f01027f8:	75 ee                	jne    f01027e8 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027fa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027fd:	89 06                	mov    %eax,(%esi)
	}
}
f01027ff:	83 c4 14             	add    $0x14,%esp
f0102802:	5b                   	pop    %ebx
f0102803:	5e                   	pop    %esi
f0102804:	5f                   	pop    %edi
f0102805:	5d                   	pop    %ebp
f0102806:	c3                   	ret    

f0102807 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102807:	55                   	push   %ebp
f0102808:	89 e5                	mov    %esp,%ebp
f010280a:	57                   	push   %edi
f010280b:	56                   	push   %esi
f010280c:	53                   	push   %ebx
f010280d:	83 ec 1c             	sub    $0x1c,%esp
f0102810:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102813:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102816:	c7 06 74 45 10 f0    	movl   $0xf0104574,(%esi)
	info->eip_line = 0;
f010281c:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0102823:	c7 46 08 74 45 10 f0 	movl   $0xf0104574,0x8(%esi)
	info->eip_fn_namelen = 9;
f010282a:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0102831:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0102834:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010283b:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0102841:	76 11                	jbe    f0102854 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102843:	b8 04 bf 10 f0       	mov    $0xf010bf04,%eax
f0102848:	3d dd a0 10 f0       	cmp    $0xf010a0dd,%eax
f010284d:	77 19                	ja     f0102868 <debuginfo_eip+0x61>
f010284f:	e9 62 01 00 00       	jmp    f01029b6 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102854:	83 ec 04             	sub    $0x4,%esp
f0102857:	68 7e 45 10 f0       	push   $0xf010457e
f010285c:	6a 7f                	push   $0x7f
f010285e:	68 8b 45 10 f0       	push   $0xf010458b
f0102863:	e8 23 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102868:	80 3d 03 bf 10 f0 00 	cmpb   $0x0,0xf010bf03
f010286f:	0f 85 48 01 00 00    	jne    f01029bd <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102875:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010287c:	b8 dc a0 10 f0       	mov    $0xf010a0dc,%eax
f0102881:	2d a8 47 10 f0       	sub    $0xf01047a8,%eax
f0102886:	c1 f8 02             	sar    $0x2,%eax
f0102889:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010288f:	83 e8 01             	sub    $0x1,%eax
f0102892:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102895:	83 ec 08             	sub    $0x8,%esp
f0102898:	57                   	push   %edi
f0102899:	6a 64                	push   $0x64
f010289b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010289e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01028a1:	b8 a8 47 10 f0       	mov    $0xf01047a8,%eax
f01028a6:	e8 66 fe ff ff       	call   f0102711 <stab_binsearch>
	if (lfile == 0)
f01028ab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028ae:	83 c4 10             	add    $0x10,%esp
f01028b1:	85 c0                	test   %eax,%eax
f01028b3:	0f 84 0b 01 00 00    	je     f01029c4 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028b9:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028bf:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028c2:	83 ec 08             	sub    $0x8,%esp
f01028c5:	57                   	push   %edi
f01028c6:	6a 24                	push   $0x24
f01028c8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028cb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028ce:	b8 a8 47 10 f0       	mov    $0xf01047a8,%eax
f01028d3:	e8 39 fe ff ff       	call   f0102711 <stab_binsearch>

	if (lfun <= rfun) {
f01028d8:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01028db:	83 c4 10             	add    $0x10,%esp
f01028de:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01028e1:	7f 31                	jg     f0102914 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028e3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028e6:	c1 e0 02             	shl    $0x2,%eax
f01028e9:	8d 90 a8 47 10 f0    	lea    -0xfefb858(%eax),%edx
f01028ef:	8b 88 a8 47 10 f0    	mov    -0xfefb858(%eax),%ecx
f01028f5:	b8 04 bf 10 f0       	mov    $0xf010bf04,%eax
f01028fa:	2d dd a0 10 f0       	sub    $0xf010a0dd,%eax
f01028ff:	39 c1                	cmp    %eax,%ecx
f0102901:	73 09                	jae    f010290c <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102903:	81 c1 dd a0 10 f0    	add    $0xf010a0dd,%ecx
f0102909:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010290c:	8b 42 08             	mov    0x8(%edx),%eax
f010290f:	89 46 10             	mov    %eax,0x10(%esi)
f0102912:	eb 06                	jmp    f010291a <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102914:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102917:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010291a:	83 ec 08             	sub    $0x8,%esp
f010291d:	6a 3a                	push   $0x3a
f010291f:	ff 76 08             	pushl  0x8(%esi)
f0102922:	e8 24 08 00 00       	call   f010314b <strfind>
f0102927:	2b 46 08             	sub    0x8(%esi),%eax
f010292a:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010292d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102930:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102933:	8d 04 85 a8 47 10 f0 	lea    -0xfefb858(,%eax,4),%eax
f010293a:	83 c4 10             	add    $0x10,%esp
f010293d:	eb 06                	jmp    f0102945 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010293f:	83 eb 01             	sub    $0x1,%ebx
f0102942:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102945:	39 fb                	cmp    %edi,%ebx
f0102947:	7c 34                	jl     f010297d <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0102949:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010294d:	80 fa 84             	cmp    $0x84,%dl
f0102950:	74 0b                	je     f010295d <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102952:	80 fa 64             	cmp    $0x64,%dl
f0102955:	75 e8                	jne    f010293f <debuginfo_eip+0x138>
f0102957:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010295b:	74 e2                	je     f010293f <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010295d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102960:	8b 14 85 a8 47 10 f0 	mov    -0xfefb858(,%eax,4),%edx
f0102967:	b8 04 bf 10 f0       	mov    $0xf010bf04,%eax
f010296c:	2d dd a0 10 f0       	sub    $0xf010a0dd,%eax
f0102971:	39 c2                	cmp    %eax,%edx
f0102973:	73 08                	jae    f010297d <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102975:	81 c2 dd a0 10 f0    	add    $0xf010a0dd,%edx
f010297b:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010297d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102980:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102983:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102988:	39 cb                	cmp    %ecx,%ebx
f010298a:	7d 44                	jge    f01029d0 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f010298c:	8d 53 01             	lea    0x1(%ebx),%edx
f010298f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102992:	8d 04 85 a8 47 10 f0 	lea    -0xfefb858(,%eax,4),%eax
f0102999:	eb 07                	jmp    f01029a2 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010299b:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010299f:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029a2:	39 ca                	cmp    %ecx,%edx
f01029a4:	74 25                	je     f01029cb <debuginfo_eip+0x1c4>
f01029a6:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029a9:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01029ad:	74 ec                	je     f010299b <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029af:	b8 00 00 00 00       	mov    $0x0,%eax
f01029b4:	eb 1a                	jmp    f01029d0 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01029b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029bb:	eb 13                	jmp    f01029d0 <debuginfo_eip+0x1c9>
f01029bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029c2:	eb 0c                	jmp    f01029d0 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01029c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029c9:	eb 05                	jmp    f01029d0 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01029d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029d3:	5b                   	pop    %ebx
f01029d4:	5e                   	pop    %esi
f01029d5:	5f                   	pop    %edi
f01029d6:	5d                   	pop    %ebp
f01029d7:	c3                   	ret    

f01029d8 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01029d8:	55                   	push   %ebp
f01029d9:	89 e5                	mov    %esp,%ebp
f01029db:	57                   	push   %edi
f01029dc:	56                   	push   %esi
f01029dd:	53                   	push   %ebx
f01029de:	83 ec 1c             	sub    $0x1c,%esp
f01029e1:	89 c7                	mov    %eax,%edi
f01029e3:	89 d6                	mov    %edx,%esi
f01029e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01029e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01029eb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01029ee:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01029f1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01029f4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01029f9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01029fc:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01029ff:	39 d3                	cmp    %edx,%ebx
f0102a01:	72 05                	jb     f0102a08 <printnum+0x30>
f0102a03:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a06:	77 45                	ja     f0102a4d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a08:	83 ec 0c             	sub    $0xc,%esp
f0102a0b:	ff 75 18             	pushl  0x18(%ebp)
f0102a0e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a11:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a14:	53                   	push   %ebx
f0102a15:	ff 75 10             	pushl  0x10(%ebp)
f0102a18:	83 ec 08             	sub    $0x8,%esp
f0102a1b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a1e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a21:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a24:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a27:	e8 44 09 00 00       	call   f0103370 <__udivdi3>
f0102a2c:	83 c4 18             	add    $0x18,%esp
f0102a2f:	52                   	push   %edx
f0102a30:	50                   	push   %eax
f0102a31:	89 f2                	mov    %esi,%edx
f0102a33:	89 f8                	mov    %edi,%eax
f0102a35:	e8 9e ff ff ff       	call   f01029d8 <printnum>
f0102a3a:	83 c4 20             	add    $0x20,%esp
f0102a3d:	eb 18                	jmp    f0102a57 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a3f:	83 ec 08             	sub    $0x8,%esp
f0102a42:	56                   	push   %esi
f0102a43:	ff 75 18             	pushl  0x18(%ebp)
f0102a46:	ff d7                	call   *%edi
f0102a48:	83 c4 10             	add    $0x10,%esp
f0102a4b:	eb 03                	jmp    f0102a50 <printnum+0x78>
f0102a4d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102a50:	83 eb 01             	sub    $0x1,%ebx
f0102a53:	85 db                	test   %ebx,%ebx
f0102a55:	7f e8                	jg     f0102a3f <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a57:	83 ec 08             	sub    $0x8,%esp
f0102a5a:	56                   	push   %esi
f0102a5b:	83 ec 04             	sub    $0x4,%esp
f0102a5e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a61:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a64:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a67:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a6a:	e8 31 0a 00 00       	call   f01034a0 <__umoddi3>
f0102a6f:	83 c4 14             	add    $0x14,%esp
f0102a72:	0f be 80 99 45 10 f0 	movsbl -0xfefba67(%eax),%eax
f0102a79:	50                   	push   %eax
f0102a7a:	ff d7                	call   *%edi
}
f0102a7c:	83 c4 10             	add    $0x10,%esp
f0102a7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a82:	5b                   	pop    %ebx
f0102a83:	5e                   	pop    %esi
f0102a84:	5f                   	pop    %edi
f0102a85:	5d                   	pop    %ebp
f0102a86:	c3                   	ret    

f0102a87 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102a87:	55                   	push   %ebp
f0102a88:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102a8a:	83 fa 01             	cmp    $0x1,%edx
f0102a8d:	7e 0e                	jle    f0102a9d <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102a8f:	8b 10                	mov    (%eax),%edx
f0102a91:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102a94:	89 08                	mov    %ecx,(%eax)
f0102a96:	8b 02                	mov    (%edx),%eax
f0102a98:	8b 52 04             	mov    0x4(%edx),%edx
f0102a9b:	eb 22                	jmp    f0102abf <getuint+0x38>
	else if (lflag)
f0102a9d:	85 d2                	test   %edx,%edx
f0102a9f:	74 10                	je     f0102ab1 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102aa1:	8b 10                	mov    (%eax),%edx
f0102aa3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102aa6:	89 08                	mov    %ecx,(%eax)
f0102aa8:	8b 02                	mov    (%edx),%eax
f0102aaa:	ba 00 00 00 00       	mov    $0x0,%edx
f0102aaf:	eb 0e                	jmp    f0102abf <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102ab1:	8b 10                	mov    (%eax),%edx
f0102ab3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102ab6:	89 08                	mov    %ecx,(%eax)
f0102ab8:	8b 02                	mov    (%edx),%eax
f0102aba:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102abf:	5d                   	pop    %ebp
f0102ac0:	c3                   	ret    

f0102ac1 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102ac1:	55                   	push   %ebp
f0102ac2:	89 e5                	mov    %esp,%ebp
f0102ac4:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102ac7:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102acb:	8b 10                	mov    (%eax),%edx
f0102acd:	3b 50 04             	cmp    0x4(%eax),%edx
f0102ad0:	73 0a                	jae    f0102adc <sprintputch+0x1b>
		*b->buf++ = ch;
f0102ad2:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102ad5:	89 08                	mov    %ecx,(%eax)
f0102ad7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ada:	88 02                	mov    %al,(%edx)
}
f0102adc:	5d                   	pop    %ebp
f0102add:	c3                   	ret    

f0102ade <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102ade:	55                   	push   %ebp
f0102adf:	89 e5                	mov    %esp,%ebp
f0102ae1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102ae4:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102ae7:	50                   	push   %eax
f0102ae8:	ff 75 10             	pushl  0x10(%ebp)
f0102aeb:	ff 75 0c             	pushl  0xc(%ebp)
f0102aee:	ff 75 08             	pushl  0x8(%ebp)
f0102af1:	e8 05 00 00 00       	call   f0102afb <vprintfmt>
	va_end(ap);
}
f0102af6:	83 c4 10             	add    $0x10,%esp
f0102af9:	c9                   	leave  
f0102afa:	c3                   	ret    

f0102afb <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102afb:	55                   	push   %ebp
f0102afc:	89 e5                	mov    %esp,%ebp
f0102afe:	57                   	push   %edi
f0102aff:	56                   	push   %esi
f0102b00:	53                   	push   %ebx
f0102b01:	83 ec 2c             	sub    $0x2c,%esp
f0102b04:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b0a:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b0d:	eb 12                	jmp    f0102b21 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b0f:	85 c0                	test   %eax,%eax
f0102b11:	0f 84 89 03 00 00    	je     f0102ea0 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102b17:	83 ec 08             	sub    $0x8,%esp
f0102b1a:	53                   	push   %ebx
f0102b1b:	50                   	push   %eax
f0102b1c:	ff d6                	call   *%esi
f0102b1e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b21:	83 c7 01             	add    $0x1,%edi
f0102b24:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b28:	83 f8 25             	cmp    $0x25,%eax
f0102b2b:	75 e2                	jne    f0102b0f <vprintfmt+0x14>
f0102b2d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b31:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b38:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b3f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b46:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b4b:	eb 07                	jmp    f0102b54 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102b50:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b54:	8d 47 01             	lea    0x1(%edi),%eax
f0102b57:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b5a:	0f b6 07             	movzbl (%edi),%eax
f0102b5d:	0f b6 c8             	movzbl %al,%ecx
f0102b60:	83 e8 23             	sub    $0x23,%eax
f0102b63:	3c 55                	cmp    $0x55,%al
f0102b65:	0f 87 1a 03 00 00    	ja     f0102e85 <vprintfmt+0x38a>
f0102b6b:	0f b6 c0             	movzbl %al,%eax
f0102b6e:	ff 24 85 24 46 10 f0 	jmp    *-0xfefb9dc(,%eax,4)
f0102b75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102b78:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102b7c:	eb d6                	jmp    f0102b54 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b81:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b86:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102b89:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102b8c:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102b90:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102b93:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102b96:	83 fa 09             	cmp    $0x9,%edx
f0102b99:	77 39                	ja     f0102bd4 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102b9b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102b9e:	eb e9                	jmp    f0102b89 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102ba0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ba3:	8d 48 04             	lea    0x4(%eax),%ecx
f0102ba6:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102ba9:	8b 00                	mov    (%eax),%eax
f0102bab:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102bb1:	eb 27                	jmp    f0102bda <vprintfmt+0xdf>
f0102bb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bb6:	85 c0                	test   %eax,%eax
f0102bb8:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102bbd:	0f 49 c8             	cmovns %eax,%ecx
f0102bc0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bc6:	eb 8c                	jmp    f0102b54 <vprintfmt+0x59>
f0102bc8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102bcb:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102bd2:	eb 80                	jmp    f0102b54 <vprintfmt+0x59>
f0102bd4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102bd7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102bda:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102bde:	0f 89 70 ff ff ff    	jns    f0102b54 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102be4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102be7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102bea:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bf1:	e9 5e ff ff ff       	jmp    f0102b54 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102bf6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102bfc:	e9 53 ff ff ff       	jmp    f0102b54 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c01:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c04:	8d 50 04             	lea    0x4(%eax),%edx
f0102c07:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c0a:	83 ec 08             	sub    $0x8,%esp
f0102c0d:	53                   	push   %ebx
f0102c0e:	ff 30                	pushl  (%eax)
f0102c10:	ff d6                	call   *%esi
			break;
f0102c12:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c18:	e9 04 ff ff ff       	jmp    f0102b21 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c1d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c20:	8d 50 04             	lea    0x4(%eax),%edx
f0102c23:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c26:	8b 00                	mov    (%eax),%eax
f0102c28:	99                   	cltd   
f0102c29:	31 d0                	xor    %edx,%eax
f0102c2b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c2d:	83 f8 06             	cmp    $0x6,%eax
f0102c30:	7f 0b                	jg     f0102c3d <vprintfmt+0x142>
f0102c32:	8b 14 85 7c 47 10 f0 	mov    -0xfefb884(,%eax,4),%edx
f0102c39:	85 d2                	test   %edx,%edx
f0102c3b:	75 18                	jne    f0102c55 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c3d:	50                   	push   %eax
f0102c3e:	68 b1 45 10 f0       	push   $0xf01045b1
f0102c43:	53                   	push   %ebx
f0102c44:	56                   	push   %esi
f0102c45:	e8 94 fe ff ff       	call   f0102ade <printfmt>
f0102c4a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c50:	e9 cc fe ff ff       	jmp    f0102b21 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c55:	52                   	push   %edx
f0102c56:	68 bc 42 10 f0       	push   $0xf01042bc
f0102c5b:	53                   	push   %ebx
f0102c5c:	56                   	push   %esi
f0102c5d:	e8 7c fe ff ff       	call   f0102ade <printfmt>
f0102c62:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c68:	e9 b4 fe ff ff       	jmp    f0102b21 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c70:	8d 50 04             	lea    0x4(%eax),%edx
f0102c73:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c76:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102c78:	85 ff                	test   %edi,%edi
f0102c7a:	b8 aa 45 10 f0       	mov    $0xf01045aa,%eax
f0102c7f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102c82:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c86:	0f 8e 94 00 00 00    	jle    f0102d20 <vprintfmt+0x225>
f0102c8c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102c90:	0f 84 98 00 00 00    	je     f0102d2e <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c96:	83 ec 08             	sub    $0x8,%esp
f0102c99:	ff 75 d0             	pushl  -0x30(%ebp)
f0102c9c:	57                   	push   %edi
f0102c9d:	e8 5f 03 00 00       	call   f0103001 <strnlen>
f0102ca2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102ca5:	29 c1                	sub    %eax,%ecx
f0102ca7:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102caa:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102cad:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102cb1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102cb4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102cb7:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cb9:	eb 0f                	jmp    f0102cca <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102cbb:	83 ec 08             	sub    $0x8,%esp
f0102cbe:	53                   	push   %ebx
f0102cbf:	ff 75 e0             	pushl  -0x20(%ebp)
f0102cc2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cc4:	83 ef 01             	sub    $0x1,%edi
f0102cc7:	83 c4 10             	add    $0x10,%esp
f0102cca:	85 ff                	test   %edi,%edi
f0102ccc:	7f ed                	jg     f0102cbb <vprintfmt+0x1c0>
f0102cce:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102cd1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102cd4:	85 c9                	test   %ecx,%ecx
f0102cd6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cdb:	0f 49 c1             	cmovns %ecx,%eax
f0102cde:	29 c1                	sub    %eax,%ecx
f0102ce0:	89 75 08             	mov    %esi,0x8(%ebp)
f0102ce3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ce6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102ce9:	89 cb                	mov    %ecx,%ebx
f0102ceb:	eb 4d                	jmp    f0102d3a <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102ced:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102cf1:	74 1b                	je     f0102d0e <vprintfmt+0x213>
f0102cf3:	0f be c0             	movsbl %al,%eax
f0102cf6:	83 e8 20             	sub    $0x20,%eax
f0102cf9:	83 f8 5e             	cmp    $0x5e,%eax
f0102cfc:	76 10                	jbe    f0102d0e <vprintfmt+0x213>
					putch('?', putdat);
f0102cfe:	83 ec 08             	sub    $0x8,%esp
f0102d01:	ff 75 0c             	pushl  0xc(%ebp)
f0102d04:	6a 3f                	push   $0x3f
f0102d06:	ff 55 08             	call   *0x8(%ebp)
f0102d09:	83 c4 10             	add    $0x10,%esp
f0102d0c:	eb 0d                	jmp    f0102d1b <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d0e:	83 ec 08             	sub    $0x8,%esp
f0102d11:	ff 75 0c             	pushl  0xc(%ebp)
f0102d14:	52                   	push   %edx
f0102d15:	ff 55 08             	call   *0x8(%ebp)
f0102d18:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d1b:	83 eb 01             	sub    $0x1,%ebx
f0102d1e:	eb 1a                	jmp    f0102d3a <vprintfmt+0x23f>
f0102d20:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d23:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d26:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d29:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d2c:	eb 0c                	jmp    f0102d3a <vprintfmt+0x23f>
f0102d2e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d31:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d34:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d37:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d3a:	83 c7 01             	add    $0x1,%edi
f0102d3d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d41:	0f be d0             	movsbl %al,%edx
f0102d44:	85 d2                	test   %edx,%edx
f0102d46:	74 23                	je     f0102d6b <vprintfmt+0x270>
f0102d48:	85 f6                	test   %esi,%esi
f0102d4a:	78 a1                	js     f0102ced <vprintfmt+0x1f2>
f0102d4c:	83 ee 01             	sub    $0x1,%esi
f0102d4f:	79 9c                	jns    f0102ced <vprintfmt+0x1f2>
f0102d51:	89 df                	mov    %ebx,%edi
f0102d53:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d56:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d59:	eb 18                	jmp    f0102d73 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102d5b:	83 ec 08             	sub    $0x8,%esp
f0102d5e:	53                   	push   %ebx
f0102d5f:	6a 20                	push   $0x20
f0102d61:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102d63:	83 ef 01             	sub    $0x1,%edi
f0102d66:	83 c4 10             	add    $0x10,%esp
f0102d69:	eb 08                	jmp    f0102d73 <vprintfmt+0x278>
f0102d6b:	89 df                	mov    %ebx,%edi
f0102d6d:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d70:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d73:	85 ff                	test   %edi,%edi
f0102d75:	7f e4                	jg     f0102d5b <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d7a:	e9 a2 fd ff ff       	jmp    f0102b21 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d7f:	83 fa 01             	cmp    $0x1,%edx
f0102d82:	7e 16                	jle    f0102d9a <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102d84:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d87:	8d 50 08             	lea    0x8(%eax),%edx
f0102d8a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d8d:	8b 50 04             	mov    0x4(%eax),%edx
f0102d90:	8b 00                	mov    (%eax),%eax
f0102d92:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d95:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102d98:	eb 32                	jmp    f0102dcc <vprintfmt+0x2d1>
	else if (lflag)
f0102d9a:	85 d2                	test   %edx,%edx
f0102d9c:	74 18                	je     f0102db6 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102d9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102da1:	8d 50 04             	lea    0x4(%eax),%edx
f0102da4:	89 55 14             	mov    %edx,0x14(%ebp)
f0102da7:	8b 00                	mov    (%eax),%eax
f0102da9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dac:	89 c1                	mov    %eax,%ecx
f0102dae:	c1 f9 1f             	sar    $0x1f,%ecx
f0102db1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102db4:	eb 16                	jmp    f0102dcc <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102db6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102db9:	8d 50 04             	lea    0x4(%eax),%edx
f0102dbc:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dbf:	8b 00                	mov    (%eax),%eax
f0102dc1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dc4:	89 c1                	mov    %eax,%ecx
f0102dc6:	c1 f9 1f             	sar    $0x1f,%ecx
f0102dc9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102dcc:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102dcf:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102dd2:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102dd7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102ddb:	79 74                	jns    f0102e51 <vprintfmt+0x356>
				putch('-', putdat);
f0102ddd:	83 ec 08             	sub    $0x8,%esp
f0102de0:	53                   	push   %ebx
f0102de1:	6a 2d                	push   $0x2d
f0102de3:	ff d6                	call   *%esi
				num = -(long long) num;
f0102de5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102de8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102deb:	f7 d8                	neg    %eax
f0102ded:	83 d2 00             	adc    $0x0,%edx
f0102df0:	f7 da                	neg    %edx
f0102df2:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102df5:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102dfa:	eb 55                	jmp    f0102e51 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102dfc:	8d 45 14             	lea    0x14(%ebp),%eax
f0102dff:	e8 83 fc ff ff       	call   f0102a87 <getuint>
			base = 10;
f0102e04:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e09:	eb 46                	jmp    f0102e51 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
				num = getuint(&ap,lflag);
f0102e0b:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e0e:	e8 74 fc ff ff       	call   f0102a87 <getuint>
			base = 8;
f0102e13:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102e18:	eb 37                	jmp    f0102e51 <vprintfmt+0x356>
			//break;

		// pointer
		case 'p':
			putch('0', putdat);
f0102e1a:	83 ec 08             	sub    $0x8,%esp
f0102e1d:	53                   	push   %ebx
f0102e1e:	6a 30                	push   $0x30
f0102e20:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e22:	83 c4 08             	add    $0x8,%esp
f0102e25:	53                   	push   %ebx
f0102e26:	6a 78                	push   $0x78
f0102e28:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e2a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e2d:	8d 50 04             	lea    0x4(%eax),%edx
f0102e30:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e33:	8b 00                	mov    (%eax),%eax
f0102e35:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e3a:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102e3d:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102e42:	eb 0d                	jmp    f0102e51 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102e44:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e47:	e8 3b fc ff ff       	call   f0102a87 <getuint>
			base = 16;
f0102e4c:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102e51:	83 ec 0c             	sub    $0xc,%esp
f0102e54:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102e58:	57                   	push   %edi
f0102e59:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e5c:	51                   	push   %ecx
f0102e5d:	52                   	push   %edx
f0102e5e:	50                   	push   %eax
f0102e5f:	89 da                	mov    %ebx,%edx
f0102e61:	89 f0                	mov    %esi,%eax
f0102e63:	e8 70 fb ff ff       	call   f01029d8 <printnum>
			break;
f0102e68:	83 c4 20             	add    $0x20,%esp
f0102e6b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e6e:	e9 ae fc ff ff       	jmp    f0102b21 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102e73:	83 ec 08             	sub    $0x8,%esp
f0102e76:	53                   	push   %ebx
f0102e77:	51                   	push   %ecx
f0102e78:	ff d6                	call   *%esi
			break;
f0102e7a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102e80:	e9 9c fc ff ff       	jmp    f0102b21 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102e85:	83 ec 08             	sub    $0x8,%esp
f0102e88:	53                   	push   %ebx
f0102e89:	6a 25                	push   $0x25
f0102e8b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102e8d:	83 c4 10             	add    $0x10,%esp
f0102e90:	eb 03                	jmp    f0102e95 <vprintfmt+0x39a>
f0102e92:	83 ef 01             	sub    $0x1,%edi
f0102e95:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102e99:	75 f7                	jne    f0102e92 <vprintfmt+0x397>
f0102e9b:	e9 81 fc ff ff       	jmp    f0102b21 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ea0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ea3:	5b                   	pop    %ebx
f0102ea4:	5e                   	pop    %esi
f0102ea5:	5f                   	pop    %edi
f0102ea6:	5d                   	pop    %ebp
f0102ea7:	c3                   	ret    

f0102ea8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102ea8:	55                   	push   %ebp
f0102ea9:	89 e5                	mov    %esp,%ebp
f0102eab:	83 ec 18             	sub    $0x18,%esp
f0102eae:	8b 45 08             	mov    0x8(%ebp),%eax
f0102eb1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102eb4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102eb7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102ebb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102ebe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102ec5:	85 c0                	test   %eax,%eax
f0102ec7:	74 26                	je     f0102eef <vsnprintf+0x47>
f0102ec9:	85 d2                	test   %edx,%edx
f0102ecb:	7e 22                	jle    f0102eef <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102ecd:	ff 75 14             	pushl  0x14(%ebp)
f0102ed0:	ff 75 10             	pushl  0x10(%ebp)
f0102ed3:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102ed6:	50                   	push   %eax
f0102ed7:	68 c1 2a 10 f0       	push   $0xf0102ac1
f0102edc:	e8 1a fc ff ff       	call   f0102afb <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102ee1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102ee4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102ee7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102eea:	83 c4 10             	add    $0x10,%esp
f0102eed:	eb 05                	jmp    f0102ef4 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102eef:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102ef4:	c9                   	leave  
f0102ef5:	c3                   	ret    

f0102ef6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102ef6:	55                   	push   %ebp
f0102ef7:	89 e5                	mov    %esp,%ebp
f0102ef9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102efc:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102eff:	50                   	push   %eax
f0102f00:	ff 75 10             	pushl  0x10(%ebp)
f0102f03:	ff 75 0c             	pushl  0xc(%ebp)
f0102f06:	ff 75 08             	pushl  0x8(%ebp)
f0102f09:	e8 9a ff ff ff       	call   f0102ea8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f0e:	c9                   	leave  
f0102f0f:	c3                   	ret    

f0102f10 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f10:	55                   	push   %ebp
f0102f11:	89 e5                	mov    %esp,%ebp
f0102f13:	57                   	push   %edi
f0102f14:	56                   	push   %esi
f0102f15:	53                   	push   %ebx
f0102f16:	83 ec 0c             	sub    $0xc,%esp
f0102f19:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f1c:	85 c0                	test   %eax,%eax
f0102f1e:	74 11                	je     f0102f31 <readline+0x21>
		cprintf("%s", prompt);
f0102f20:	83 ec 08             	sub    $0x8,%esp
f0102f23:	50                   	push   %eax
f0102f24:	68 bc 42 10 f0       	push   $0xf01042bc
f0102f29:	e8 cf f7 ff ff       	call   f01026fd <cprintf>
f0102f2e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f31:	83 ec 0c             	sub    $0xc,%esp
f0102f34:	6a 00                	push   $0x0
f0102f36:	e8 e6 d6 ff ff       	call   f0100621 <iscons>
f0102f3b:	89 c7                	mov    %eax,%edi
f0102f3d:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f40:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f45:	e8 c6 d6 ff ff       	call   f0100610 <getchar>
f0102f4a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f4c:	85 c0                	test   %eax,%eax
f0102f4e:	79 18                	jns    f0102f68 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102f50:	83 ec 08             	sub    $0x8,%esp
f0102f53:	50                   	push   %eax
f0102f54:	68 98 47 10 f0       	push   $0xf0104798
f0102f59:	e8 9f f7 ff ff       	call   f01026fd <cprintf>
			return NULL;
f0102f5e:	83 c4 10             	add    $0x10,%esp
f0102f61:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f66:	eb 79                	jmp    f0102fe1 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102f68:	83 f8 08             	cmp    $0x8,%eax
f0102f6b:	0f 94 c2             	sete   %dl
f0102f6e:	83 f8 7f             	cmp    $0x7f,%eax
f0102f71:	0f 94 c0             	sete   %al
f0102f74:	08 c2                	or     %al,%dl
f0102f76:	74 1a                	je     f0102f92 <readline+0x82>
f0102f78:	85 f6                	test   %esi,%esi
f0102f7a:	7e 16                	jle    f0102f92 <readline+0x82>
			if (echoing)
f0102f7c:	85 ff                	test   %edi,%edi
f0102f7e:	74 0d                	je     f0102f8d <readline+0x7d>
				cputchar('\b');
f0102f80:	83 ec 0c             	sub    $0xc,%esp
f0102f83:	6a 08                	push   $0x8
f0102f85:	e8 76 d6 ff ff       	call   f0100600 <cputchar>
f0102f8a:	83 c4 10             	add    $0x10,%esp
			i--;
f0102f8d:	83 ee 01             	sub    $0x1,%esi
f0102f90:	eb b3                	jmp    f0102f45 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102f92:	83 fb 1f             	cmp    $0x1f,%ebx
f0102f95:	7e 23                	jle    f0102fba <readline+0xaa>
f0102f97:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102f9d:	7f 1b                	jg     f0102fba <readline+0xaa>
			if (echoing)
f0102f9f:	85 ff                	test   %edi,%edi
f0102fa1:	74 0c                	je     f0102faf <readline+0x9f>
				cputchar(c);
f0102fa3:	83 ec 0c             	sub    $0xc,%esp
f0102fa6:	53                   	push   %ebx
f0102fa7:	e8 54 d6 ff ff       	call   f0100600 <cputchar>
f0102fac:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102faf:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0102fb5:	8d 76 01             	lea    0x1(%esi),%esi
f0102fb8:	eb 8b                	jmp    f0102f45 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102fba:	83 fb 0a             	cmp    $0xa,%ebx
f0102fbd:	74 05                	je     f0102fc4 <readline+0xb4>
f0102fbf:	83 fb 0d             	cmp    $0xd,%ebx
f0102fc2:	75 81                	jne    f0102f45 <readline+0x35>
			if (echoing)
f0102fc4:	85 ff                	test   %edi,%edi
f0102fc6:	74 0d                	je     f0102fd5 <readline+0xc5>
				cputchar('\n');
f0102fc8:	83 ec 0c             	sub    $0xc,%esp
f0102fcb:	6a 0a                	push   $0xa
f0102fcd:	e8 2e d6 ff ff       	call   f0100600 <cputchar>
f0102fd2:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102fd5:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0102fdc:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0102fe1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fe4:	5b                   	pop    %ebx
f0102fe5:	5e                   	pop    %esi
f0102fe6:	5f                   	pop    %edi
f0102fe7:	5d                   	pop    %ebp
f0102fe8:	c3                   	ret    

f0102fe9 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102fe9:	55                   	push   %ebp
f0102fea:	89 e5                	mov    %esp,%ebp
f0102fec:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102fef:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ff4:	eb 03                	jmp    f0102ff9 <strlen+0x10>
		n++;
f0102ff6:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102ff9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102ffd:	75 f7                	jne    f0102ff6 <strlen+0xd>
		n++;
	return n;
}
f0102fff:	5d                   	pop    %ebp
f0103000:	c3                   	ret    

f0103001 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103001:	55                   	push   %ebp
f0103002:	89 e5                	mov    %esp,%ebp
f0103004:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103007:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010300a:	ba 00 00 00 00       	mov    $0x0,%edx
f010300f:	eb 03                	jmp    f0103014 <strnlen+0x13>
		n++;
f0103011:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103014:	39 c2                	cmp    %eax,%edx
f0103016:	74 08                	je     f0103020 <strnlen+0x1f>
f0103018:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010301c:	75 f3                	jne    f0103011 <strnlen+0x10>
f010301e:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103020:	5d                   	pop    %ebp
f0103021:	c3                   	ret    

f0103022 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103022:	55                   	push   %ebp
f0103023:	89 e5                	mov    %esp,%ebp
f0103025:	53                   	push   %ebx
f0103026:	8b 45 08             	mov    0x8(%ebp),%eax
f0103029:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010302c:	89 c2                	mov    %eax,%edx
f010302e:	83 c2 01             	add    $0x1,%edx
f0103031:	83 c1 01             	add    $0x1,%ecx
f0103034:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103038:	88 5a ff             	mov    %bl,-0x1(%edx)
f010303b:	84 db                	test   %bl,%bl
f010303d:	75 ef                	jne    f010302e <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010303f:	5b                   	pop    %ebx
f0103040:	5d                   	pop    %ebp
f0103041:	c3                   	ret    

f0103042 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103042:	55                   	push   %ebp
f0103043:	89 e5                	mov    %esp,%ebp
f0103045:	53                   	push   %ebx
f0103046:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103049:	53                   	push   %ebx
f010304a:	e8 9a ff ff ff       	call   f0102fe9 <strlen>
f010304f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103052:	ff 75 0c             	pushl  0xc(%ebp)
f0103055:	01 d8                	add    %ebx,%eax
f0103057:	50                   	push   %eax
f0103058:	e8 c5 ff ff ff       	call   f0103022 <strcpy>
	return dst;
}
f010305d:	89 d8                	mov    %ebx,%eax
f010305f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103062:	c9                   	leave  
f0103063:	c3                   	ret    

f0103064 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103064:	55                   	push   %ebp
f0103065:	89 e5                	mov    %esp,%ebp
f0103067:	56                   	push   %esi
f0103068:	53                   	push   %ebx
f0103069:	8b 75 08             	mov    0x8(%ebp),%esi
f010306c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010306f:	89 f3                	mov    %esi,%ebx
f0103071:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103074:	89 f2                	mov    %esi,%edx
f0103076:	eb 0f                	jmp    f0103087 <strncpy+0x23>
		*dst++ = *src;
f0103078:	83 c2 01             	add    $0x1,%edx
f010307b:	0f b6 01             	movzbl (%ecx),%eax
f010307e:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103081:	80 39 01             	cmpb   $0x1,(%ecx)
f0103084:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103087:	39 da                	cmp    %ebx,%edx
f0103089:	75 ed                	jne    f0103078 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010308b:	89 f0                	mov    %esi,%eax
f010308d:	5b                   	pop    %ebx
f010308e:	5e                   	pop    %esi
f010308f:	5d                   	pop    %ebp
f0103090:	c3                   	ret    

f0103091 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103091:	55                   	push   %ebp
f0103092:	89 e5                	mov    %esp,%ebp
f0103094:	56                   	push   %esi
f0103095:	53                   	push   %ebx
f0103096:	8b 75 08             	mov    0x8(%ebp),%esi
f0103099:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010309c:	8b 55 10             	mov    0x10(%ebp),%edx
f010309f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01030a1:	85 d2                	test   %edx,%edx
f01030a3:	74 21                	je     f01030c6 <strlcpy+0x35>
f01030a5:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01030a9:	89 f2                	mov    %esi,%edx
f01030ab:	eb 09                	jmp    f01030b6 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01030ad:	83 c2 01             	add    $0x1,%edx
f01030b0:	83 c1 01             	add    $0x1,%ecx
f01030b3:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01030b6:	39 c2                	cmp    %eax,%edx
f01030b8:	74 09                	je     f01030c3 <strlcpy+0x32>
f01030ba:	0f b6 19             	movzbl (%ecx),%ebx
f01030bd:	84 db                	test   %bl,%bl
f01030bf:	75 ec                	jne    f01030ad <strlcpy+0x1c>
f01030c1:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01030c3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01030c6:	29 f0                	sub    %esi,%eax
}
f01030c8:	5b                   	pop    %ebx
f01030c9:	5e                   	pop    %esi
f01030ca:	5d                   	pop    %ebp
f01030cb:	c3                   	ret    

f01030cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01030cc:	55                   	push   %ebp
f01030cd:	89 e5                	mov    %esp,%ebp
f01030cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01030d5:	eb 06                	jmp    f01030dd <strcmp+0x11>
		p++, q++;
f01030d7:	83 c1 01             	add    $0x1,%ecx
f01030da:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01030dd:	0f b6 01             	movzbl (%ecx),%eax
f01030e0:	84 c0                	test   %al,%al
f01030e2:	74 04                	je     f01030e8 <strcmp+0x1c>
f01030e4:	3a 02                	cmp    (%edx),%al
f01030e6:	74 ef                	je     f01030d7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01030e8:	0f b6 c0             	movzbl %al,%eax
f01030eb:	0f b6 12             	movzbl (%edx),%edx
f01030ee:	29 d0                	sub    %edx,%eax
}
f01030f0:	5d                   	pop    %ebp
f01030f1:	c3                   	ret    

f01030f2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01030f2:	55                   	push   %ebp
f01030f3:	89 e5                	mov    %esp,%ebp
f01030f5:	53                   	push   %ebx
f01030f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01030f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01030fc:	89 c3                	mov    %eax,%ebx
f01030fe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103101:	eb 06                	jmp    f0103109 <strncmp+0x17>
		n--, p++, q++;
f0103103:	83 c0 01             	add    $0x1,%eax
f0103106:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103109:	39 d8                	cmp    %ebx,%eax
f010310b:	74 15                	je     f0103122 <strncmp+0x30>
f010310d:	0f b6 08             	movzbl (%eax),%ecx
f0103110:	84 c9                	test   %cl,%cl
f0103112:	74 04                	je     f0103118 <strncmp+0x26>
f0103114:	3a 0a                	cmp    (%edx),%cl
f0103116:	74 eb                	je     f0103103 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103118:	0f b6 00             	movzbl (%eax),%eax
f010311b:	0f b6 12             	movzbl (%edx),%edx
f010311e:	29 d0                	sub    %edx,%eax
f0103120:	eb 05                	jmp    f0103127 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103122:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103127:	5b                   	pop    %ebx
f0103128:	5d                   	pop    %ebp
f0103129:	c3                   	ret    

f010312a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010312a:	55                   	push   %ebp
f010312b:	89 e5                	mov    %esp,%ebp
f010312d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103130:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103134:	eb 07                	jmp    f010313d <strchr+0x13>
		if (*s == c)
f0103136:	38 ca                	cmp    %cl,%dl
f0103138:	74 0f                	je     f0103149 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010313a:	83 c0 01             	add    $0x1,%eax
f010313d:	0f b6 10             	movzbl (%eax),%edx
f0103140:	84 d2                	test   %dl,%dl
f0103142:	75 f2                	jne    f0103136 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103144:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103149:	5d                   	pop    %ebp
f010314a:	c3                   	ret    

f010314b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010314b:	55                   	push   %ebp
f010314c:	89 e5                	mov    %esp,%ebp
f010314e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103151:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103155:	eb 03                	jmp    f010315a <strfind+0xf>
f0103157:	83 c0 01             	add    $0x1,%eax
f010315a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010315d:	38 ca                	cmp    %cl,%dl
f010315f:	74 04                	je     f0103165 <strfind+0x1a>
f0103161:	84 d2                	test   %dl,%dl
f0103163:	75 f2                	jne    f0103157 <strfind+0xc>
			break;
	return (char *) s;
}
f0103165:	5d                   	pop    %ebp
f0103166:	c3                   	ret    

f0103167 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103167:	55                   	push   %ebp
f0103168:	89 e5                	mov    %esp,%ebp
f010316a:	57                   	push   %edi
f010316b:	56                   	push   %esi
f010316c:	53                   	push   %ebx
f010316d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103170:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103173:	85 c9                	test   %ecx,%ecx
f0103175:	74 36                	je     f01031ad <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103177:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010317d:	75 28                	jne    f01031a7 <memset+0x40>
f010317f:	f6 c1 03             	test   $0x3,%cl
f0103182:	75 23                	jne    f01031a7 <memset+0x40>
		c &= 0xFF;
f0103184:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103188:	89 d3                	mov    %edx,%ebx
f010318a:	c1 e3 08             	shl    $0x8,%ebx
f010318d:	89 d6                	mov    %edx,%esi
f010318f:	c1 e6 18             	shl    $0x18,%esi
f0103192:	89 d0                	mov    %edx,%eax
f0103194:	c1 e0 10             	shl    $0x10,%eax
f0103197:	09 f0                	or     %esi,%eax
f0103199:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010319b:	89 d8                	mov    %ebx,%eax
f010319d:	09 d0                	or     %edx,%eax
f010319f:	c1 e9 02             	shr    $0x2,%ecx
f01031a2:	fc                   	cld    
f01031a3:	f3 ab                	rep stos %eax,%es:(%edi)
f01031a5:	eb 06                	jmp    f01031ad <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01031a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031aa:	fc                   	cld    
f01031ab:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01031ad:	89 f8                	mov    %edi,%eax
f01031af:	5b                   	pop    %ebx
f01031b0:	5e                   	pop    %esi
f01031b1:	5f                   	pop    %edi
f01031b2:	5d                   	pop    %ebp
f01031b3:	c3                   	ret    

f01031b4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01031b4:	55                   	push   %ebp
f01031b5:	89 e5                	mov    %esp,%ebp
f01031b7:	57                   	push   %edi
f01031b8:	56                   	push   %esi
f01031b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01031bc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01031bf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01031c2:	39 c6                	cmp    %eax,%esi
f01031c4:	73 35                	jae    f01031fb <memmove+0x47>
f01031c6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01031c9:	39 d0                	cmp    %edx,%eax
f01031cb:	73 2e                	jae    f01031fb <memmove+0x47>
		s += n;
		d += n;
f01031cd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031d0:	89 d6                	mov    %edx,%esi
f01031d2:	09 fe                	or     %edi,%esi
f01031d4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01031da:	75 13                	jne    f01031ef <memmove+0x3b>
f01031dc:	f6 c1 03             	test   $0x3,%cl
f01031df:	75 0e                	jne    f01031ef <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01031e1:	83 ef 04             	sub    $0x4,%edi
f01031e4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01031e7:	c1 e9 02             	shr    $0x2,%ecx
f01031ea:	fd                   	std    
f01031eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031ed:	eb 09                	jmp    f01031f8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01031ef:	83 ef 01             	sub    $0x1,%edi
f01031f2:	8d 72 ff             	lea    -0x1(%edx),%esi
f01031f5:	fd                   	std    
f01031f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01031f8:	fc                   	cld    
f01031f9:	eb 1d                	jmp    f0103218 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031fb:	89 f2                	mov    %esi,%edx
f01031fd:	09 c2                	or     %eax,%edx
f01031ff:	f6 c2 03             	test   $0x3,%dl
f0103202:	75 0f                	jne    f0103213 <memmove+0x5f>
f0103204:	f6 c1 03             	test   $0x3,%cl
f0103207:	75 0a                	jne    f0103213 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103209:	c1 e9 02             	shr    $0x2,%ecx
f010320c:	89 c7                	mov    %eax,%edi
f010320e:	fc                   	cld    
f010320f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103211:	eb 05                	jmp    f0103218 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103213:	89 c7                	mov    %eax,%edi
f0103215:	fc                   	cld    
f0103216:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103218:	5e                   	pop    %esi
f0103219:	5f                   	pop    %edi
f010321a:	5d                   	pop    %ebp
f010321b:	c3                   	ret    

f010321c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010321c:	55                   	push   %ebp
f010321d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010321f:	ff 75 10             	pushl  0x10(%ebp)
f0103222:	ff 75 0c             	pushl  0xc(%ebp)
f0103225:	ff 75 08             	pushl  0x8(%ebp)
f0103228:	e8 87 ff ff ff       	call   f01031b4 <memmove>
}
f010322d:	c9                   	leave  
f010322e:	c3                   	ret    

f010322f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010322f:	55                   	push   %ebp
f0103230:	89 e5                	mov    %esp,%ebp
f0103232:	56                   	push   %esi
f0103233:	53                   	push   %ebx
f0103234:	8b 45 08             	mov    0x8(%ebp),%eax
f0103237:	8b 55 0c             	mov    0xc(%ebp),%edx
f010323a:	89 c6                	mov    %eax,%esi
f010323c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010323f:	eb 1a                	jmp    f010325b <memcmp+0x2c>
		if (*s1 != *s2)
f0103241:	0f b6 08             	movzbl (%eax),%ecx
f0103244:	0f b6 1a             	movzbl (%edx),%ebx
f0103247:	38 d9                	cmp    %bl,%cl
f0103249:	74 0a                	je     f0103255 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010324b:	0f b6 c1             	movzbl %cl,%eax
f010324e:	0f b6 db             	movzbl %bl,%ebx
f0103251:	29 d8                	sub    %ebx,%eax
f0103253:	eb 0f                	jmp    f0103264 <memcmp+0x35>
		s1++, s2++;
f0103255:	83 c0 01             	add    $0x1,%eax
f0103258:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010325b:	39 f0                	cmp    %esi,%eax
f010325d:	75 e2                	jne    f0103241 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010325f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103264:	5b                   	pop    %ebx
f0103265:	5e                   	pop    %esi
f0103266:	5d                   	pop    %ebp
f0103267:	c3                   	ret    

f0103268 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103268:	55                   	push   %ebp
f0103269:	89 e5                	mov    %esp,%ebp
f010326b:	53                   	push   %ebx
f010326c:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010326f:	89 c1                	mov    %eax,%ecx
f0103271:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103274:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103278:	eb 0a                	jmp    f0103284 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010327a:	0f b6 10             	movzbl (%eax),%edx
f010327d:	39 da                	cmp    %ebx,%edx
f010327f:	74 07                	je     f0103288 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103281:	83 c0 01             	add    $0x1,%eax
f0103284:	39 c8                	cmp    %ecx,%eax
f0103286:	72 f2                	jb     f010327a <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103288:	5b                   	pop    %ebx
f0103289:	5d                   	pop    %ebp
f010328a:	c3                   	ret    

f010328b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010328b:	55                   	push   %ebp
f010328c:	89 e5                	mov    %esp,%ebp
f010328e:	57                   	push   %edi
f010328f:	56                   	push   %esi
f0103290:	53                   	push   %ebx
f0103291:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103294:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103297:	eb 03                	jmp    f010329c <strtol+0x11>
		s++;
f0103299:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010329c:	0f b6 01             	movzbl (%ecx),%eax
f010329f:	3c 20                	cmp    $0x20,%al
f01032a1:	74 f6                	je     f0103299 <strtol+0xe>
f01032a3:	3c 09                	cmp    $0x9,%al
f01032a5:	74 f2                	je     f0103299 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01032a7:	3c 2b                	cmp    $0x2b,%al
f01032a9:	75 0a                	jne    f01032b5 <strtol+0x2a>
		s++;
f01032ab:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01032ae:	bf 00 00 00 00       	mov    $0x0,%edi
f01032b3:	eb 11                	jmp    f01032c6 <strtol+0x3b>
f01032b5:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01032ba:	3c 2d                	cmp    $0x2d,%al
f01032bc:	75 08                	jne    f01032c6 <strtol+0x3b>
		s++, neg = 1;
f01032be:	83 c1 01             	add    $0x1,%ecx
f01032c1:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01032c6:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01032cc:	75 15                	jne    f01032e3 <strtol+0x58>
f01032ce:	80 39 30             	cmpb   $0x30,(%ecx)
f01032d1:	75 10                	jne    f01032e3 <strtol+0x58>
f01032d3:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01032d7:	75 7c                	jne    f0103355 <strtol+0xca>
		s += 2, base = 16;
f01032d9:	83 c1 02             	add    $0x2,%ecx
f01032dc:	bb 10 00 00 00       	mov    $0x10,%ebx
f01032e1:	eb 16                	jmp    f01032f9 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01032e3:	85 db                	test   %ebx,%ebx
f01032e5:	75 12                	jne    f01032f9 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01032e7:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01032ec:	80 39 30             	cmpb   $0x30,(%ecx)
f01032ef:	75 08                	jne    f01032f9 <strtol+0x6e>
		s++, base = 8;
f01032f1:	83 c1 01             	add    $0x1,%ecx
f01032f4:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01032f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01032fe:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103301:	0f b6 11             	movzbl (%ecx),%edx
f0103304:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103307:	89 f3                	mov    %esi,%ebx
f0103309:	80 fb 09             	cmp    $0x9,%bl
f010330c:	77 08                	ja     f0103316 <strtol+0x8b>
			dig = *s - '0';
f010330e:	0f be d2             	movsbl %dl,%edx
f0103311:	83 ea 30             	sub    $0x30,%edx
f0103314:	eb 22                	jmp    f0103338 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103316:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103319:	89 f3                	mov    %esi,%ebx
f010331b:	80 fb 19             	cmp    $0x19,%bl
f010331e:	77 08                	ja     f0103328 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103320:	0f be d2             	movsbl %dl,%edx
f0103323:	83 ea 57             	sub    $0x57,%edx
f0103326:	eb 10                	jmp    f0103338 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103328:	8d 72 bf             	lea    -0x41(%edx),%esi
f010332b:	89 f3                	mov    %esi,%ebx
f010332d:	80 fb 19             	cmp    $0x19,%bl
f0103330:	77 16                	ja     f0103348 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103332:	0f be d2             	movsbl %dl,%edx
f0103335:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103338:	3b 55 10             	cmp    0x10(%ebp),%edx
f010333b:	7d 0b                	jge    f0103348 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010333d:	83 c1 01             	add    $0x1,%ecx
f0103340:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103344:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103346:	eb b9                	jmp    f0103301 <strtol+0x76>

	if (endptr)
f0103348:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010334c:	74 0d                	je     f010335b <strtol+0xd0>
		*endptr = (char *) s;
f010334e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103351:	89 0e                	mov    %ecx,(%esi)
f0103353:	eb 06                	jmp    f010335b <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103355:	85 db                	test   %ebx,%ebx
f0103357:	74 98                	je     f01032f1 <strtol+0x66>
f0103359:	eb 9e                	jmp    f01032f9 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010335b:	89 c2                	mov    %eax,%edx
f010335d:	f7 da                	neg    %edx
f010335f:	85 ff                	test   %edi,%edi
f0103361:	0f 45 c2             	cmovne %edx,%eax
}
f0103364:	5b                   	pop    %ebx
f0103365:	5e                   	pop    %esi
f0103366:	5f                   	pop    %edi
f0103367:	5d                   	pop    %ebp
f0103368:	c3                   	ret    
f0103369:	66 90                	xchg   %ax,%ax
f010336b:	66 90                	xchg   %ax,%ax
f010336d:	66 90                	xchg   %ax,%ax
f010336f:	90                   	nop

f0103370 <__udivdi3>:
f0103370:	55                   	push   %ebp
f0103371:	57                   	push   %edi
f0103372:	56                   	push   %esi
f0103373:	53                   	push   %ebx
f0103374:	83 ec 1c             	sub    $0x1c,%esp
f0103377:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010337b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010337f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103383:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103387:	85 f6                	test   %esi,%esi
f0103389:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010338d:	89 ca                	mov    %ecx,%edx
f010338f:	89 f8                	mov    %edi,%eax
f0103391:	75 3d                	jne    f01033d0 <__udivdi3+0x60>
f0103393:	39 cf                	cmp    %ecx,%edi
f0103395:	0f 87 c5 00 00 00    	ja     f0103460 <__udivdi3+0xf0>
f010339b:	85 ff                	test   %edi,%edi
f010339d:	89 fd                	mov    %edi,%ebp
f010339f:	75 0b                	jne    f01033ac <__udivdi3+0x3c>
f01033a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01033a6:	31 d2                	xor    %edx,%edx
f01033a8:	f7 f7                	div    %edi
f01033aa:	89 c5                	mov    %eax,%ebp
f01033ac:	89 c8                	mov    %ecx,%eax
f01033ae:	31 d2                	xor    %edx,%edx
f01033b0:	f7 f5                	div    %ebp
f01033b2:	89 c1                	mov    %eax,%ecx
f01033b4:	89 d8                	mov    %ebx,%eax
f01033b6:	89 cf                	mov    %ecx,%edi
f01033b8:	f7 f5                	div    %ebp
f01033ba:	89 c3                	mov    %eax,%ebx
f01033bc:	89 d8                	mov    %ebx,%eax
f01033be:	89 fa                	mov    %edi,%edx
f01033c0:	83 c4 1c             	add    $0x1c,%esp
f01033c3:	5b                   	pop    %ebx
f01033c4:	5e                   	pop    %esi
f01033c5:	5f                   	pop    %edi
f01033c6:	5d                   	pop    %ebp
f01033c7:	c3                   	ret    
f01033c8:	90                   	nop
f01033c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01033d0:	39 ce                	cmp    %ecx,%esi
f01033d2:	77 74                	ja     f0103448 <__udivdi3+0xd8>
f01033d4:	0f bd fe             	bsr    %esi,%edi
f01033d7:	83 f7 1f             	xor    $0x1f,%edi
f01033da:	0f 84 98 00 00 00    	je     f0103478 <__udivdi3+0x108>
f01033e0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01033e5:	89 f9                	mov    %edi,%ecx
f01033e7:	89 c5                	mov    %eax,%ebp
f01033e9:	29 fb                	sub    %edi,%ebx
f01033eb:	d3 e6                	shl    %cl,%esi
f01033ed:	89 d9                	mov    %ebx,%ecx
f01033ef:	d3 ed                	shr    %cl,%ebp
f01033f1:	89 f9                	mov    %edi,%ecx
f01033f3:	d3 e0                	shl    %cl,%eax
f01033f5:	09 ee                	or     %ebp,%esi
f01033f7:	89 d9                	mov    %ebx,%ecx
f01033f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033fd:	89 d5                	mov    %edx,%ebp
f01033ff:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103403:	d3 ed                	shr    %cl,%ebp
f0103405:	89 f9                	mov    %edi,%ecx
f0103407:	d3 e2                	shl    %cl,%edx
f0103409:	89 d9                	mov    %ebx,%ecx
f010340b:	d3 e8                	shr    %cl,%eax
f010340d:	09 c2                	or     %eax,%edx
f010340f:	89 d0                	mov    %edx,%eax
f0103411:	89 ea                	mov    %ebp,%edx
f0103413:	f7 f6                	div    %esi
f0103415:	89 d5                	mov    %edx,%ebp
f0103417:	89 c3                	mov    %eax,%ebx
f0103419:	f7 64 24 0c          	mull   0xc(%esp)
f010341d:	39 d5                	cmp    %edx,%ebp
f010341f:	72 10                	jb     f0103431 <__udivdi3+0xc1>
f0103421:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103425:	89 f9                	mov    %edi,%ecx
f0103427:	d3 e6                	shl    %cl,%esi
f0103429:	39 c6                	cmp    %eax,%esi
f010342b:	73 07                	jae    f0103434 <__udivdi3+0xc4>
f010342d:	39 d5                	cmp    %edx,%ebp
f010342f:	75 03                	jne    f0103434 <__udivdi3+0xc4>
f0103431:	83 eb 01             	sub    $0x1,%ebx
f0103434:	31 ff                	xor    %edi,%edi
f0103436:	89 d8                	mov    %ebx,%eax
f0103438:	89 fa                	mov    %edi,%edx
f010343a:	83 c4 1c             	add    $0x1c,%esp
f010343d:	5b                   	pop    %ebx
f010343e:	5e                   	pop    %esi
f010343f:	5f                   	pop    %edi
f0103440:	5d                   	pop    %ebp
f0103441:	c3                   	ret    
f0103442:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103448:	31 ff                	xor    %edi,%edi
f010344a:	31 db                	xor    %ebx,%ebx
f010344c:	89 d8                	mov    %ebx,%eax
f010344e:	89 fa                	mov    %edi,%edx
f0103450:	83 c4 1c             	add    $0x1c,%esp
f0103453:	5b                   	pop    %ebx
f0103454:	5e                   	pop    %esi
f0103455:	5f                   	pop    %edi
f0103456:	5d                   	pop    %ebp
f0103457:	c3                   	ret    
f0103458:	90                   	nop
f0103459:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103460:	89 d8                	mov    %ebx,%eax
f0103462:	f7 f7                	div    %edi
f0103464:	31 ff                	xor    %edi,%edi
f0103466:	89 c3                	mov    %eax,%ebx
f0103468:	89 d8                	mov    %ebx,%eax
f010346a:	89 fa                	mov    %edi,%edx
f010346c:	83 c4 1c             	add    $0x1c,%esp
f010346f:	5b                   	pop    %ebx
f0103470:	5e                   	pop    %esi
f0103471:	5f                   	pop    %edi
f0103472:	5d                   	pop    %ebp
f0103473:	c3                   	ret    
f0103474:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103478:	39 ce                	cmp    %ecx,%esi
f010347a:	72 0c                	jb     f0103488 <__udivdi3+0x118>
f010347c:	31 db                	xor    %ebx,%ebx
f010347e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103482:	0f 87 34 ff ff ff    	ja     f01033bc <__udivdi3+0x4c>
f0103488:	bb 01 00 00 00       	mov    $0x1,%ebx
f010348d:	e9 2a ff ff ff       	jmp    f01033bc <__udivdi3+0x4c>
f0103492:	66 90                	xchg   %ax,%ax
f0103494:	66 90                	xchg   %ax,%ax
f0103496:	66 90                	xchg   %ax,%ax
f0103498:	66 90                	xchg   %ax,%ax
f010349a:	66 90                	xchg   %ax,%ax
f010349c:	66 90                	xchg   %ax,%ax
f010349e:	66 90                	xchg   %ax,%ax

f01034a0 <__umoddi3>:
f01034a0:	55                   	push   %ebp
f01034a1:	57                   	push   %edi
f01034a2:	56                   	push   %esi
f01034a3:	53                   	push   %ebx
f01034a4:	83 ec 1c             	sub    $0x1c,%esp
f01034a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01034ab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01034af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01034b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034b7:	85 d2                	test   %edx,%edx
f01034b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01034bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01034c1:	89 f3                	mov    %esi,%ebx
f01034c3:	89 3c 24             	mov    %edi,(%esp)
f01034c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034ca:	75 1c                	jne    f01034e8 <__umoddi3+0x48>
f01034cc:	39 f7                	cmp    %esi,%edi
f01034ce:	76 50                	jbe    f0103520 <__umoddi3+0x80>
f01034d0:	89 c8                	mov    %ecx,%eax
f01034d2:	89 f2                	mov    %esi,%edx
f01034d4:	f7 f7                	div    %edi
f01034d6:	89 d0                	mov    %edx,%eax
f01034d8:	31 d2                	xor    %edx,%edx
f01034da:	83 c4 1c             	add    $0x1c,%esp
f01034dd:	5b                   	pop    %ebx
f01034de:	5e                   	pop    %esi
f01034df:	5f                   	pop    %edi
f01034e0:	5d                   	pop    %ebp
f01034e1:	c3                   	ret    
f01034e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034e8:	39 f2                	cmp    %esi,%edx
f01034ea:	89 d0                	mov    %edx,%eax
f01034ec:	77 52                	ja     f0103540 <__umoddi3+0xa0>
f01034ee:	0f bd ea             	bsr    %edx,%ebp
f01034f1:	83 f5 1f             	xor    $0x1f,%ebp
f01034f4:	75 5a                	jne    f0103550 <__umoddi3+0xb0>
f01034f6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01034fa:	0f 82 e0 00 00 00    	jb     f01035e0 <__umoddi3+0x140>
f0103500:	39 0c 24             	cmp    %ecx,(%esp)
f0103503:	0f 86 d7 00 00 00    	jbe    f01035e0 <__umoddi3+0x140>
f0103509:	8b 44 24 08          	mov    0x8(%esp),%eax
f010350d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103511:	83 c4 1c             	add    $0x1c,%esp
f0103514:	5b                   	pop    %ebx
f0103515:	5e                   	pop    %esi
f0103516:	5f                   	pop    %edi
f0103517:	5d                   	pop    %ebp
f0103518:	c3                   	ret    
f0103519:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103520:	85 ff                	test   %edi,%edi
f0103522:	89 fd                	mov    %edi,%ebp
f0103524:	75 0b                	jne    f0103531 <__umoddi3+0x91>
f0103526:	b8 01 00 00 00       	mov    $0x1,%eax
f010352b:	31 d2                	xor    %edx,%edx
f010352d:	f7 f7                	div    %edi
f010352f:	89 c5                	mov    %eax,%ebp
f0103531:	89 f0                	mov    %esi,%eax
f0103533:	31 d2                	xor    %edx,%edx
f0103535:	f7 f5                	div    %ebp
f0103537:	89 c8                	mov    %ecx,%eax
f0103539:	f7 f5                	div    %ebp
f010353b:	89 d0                	mov    %edx,%eax
f010353d:	eb 99                	jmp    f01034d8 <__umoddi3+0x38>
f010353f:	90                   	nop
f0103540:	89 c8                	mov    %ecx,%eax
f0103542:	89 f2                	mov    %esi,%edx
f0103544:	83 c4 1c             	add    $0x1c,%esp
f0103547:	5b                   	pop    %ebx
f0103548:	5e                   	pop    %esi
f0103549:	5f                   	pop    %edi
f010354a:	5d                   	pop    %ebp
f010354b:	c3                   	ret    
f010354c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103550:	8b 34 24             	mov    (%esp),%esi
f0103553:	bf 20 00 00 00       	mov    $0x20,%edi
f0103558:	89 e9                	mov    %ebp,%ecx
f010355a:	29 ef                	sub    %ebp,%edi
f010355c:	d3 e0                	shl    %cl,%eax
f010355e:	89 f9                	mov    %edi,%ecx
f0103560:	89 f2                	mov    %esi,%edx
f0103562:	d3 ea                	shr    %cl,%edx
f0103564:	89 e9                	mov    %ebp,%ecx
f0103566:	09 c2                	or     %eax,%edx
f0103568:	89 d8                	mov    %ebx,%eax
f010356a:	89 14 24             	mov    %edx,(%esp)
f010356d:	89 f2                	mov    %esi,%edx
f010356f:	d3 e2                	shl    %cl,%edx
f0103571:	89 f9                	mov    %edi,%ecx
f0103573:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103577:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010357b:	d3 e8                	shr    %cl,%eax
f010357d:	89 e9                	mov    %ebp,%ecx
f010357f:	89 c6                	mov    %eax,%esi
f0103581:	d3 e3                	shl    %cl,%ebx
f0103583:	89 f9                	mov    %edi,%ecx
f0103585:	89 d0                	mov    %edx,%eax
f0103587:	d3 e8                	shr    %cl,%eax
f0103589:	89 e9                	mov    %ebp,%ecx
f010358b:	09 d8                	or     %ebx,%eax
f010358d:	89 d3                	mov    %edx,%ebx
f010358f:	89 f2                	mov    %esi,%edx
f0103591:	f7 34 24             	divl   (%esp)
f0103594:	89 d6                	mov    %edx,%esi
f0103596:	d3 e3                	shl    %cl,%ebx
f0103598:	f7 64 24 04          	mull   0x4(%esp)
f010359c:	39 d6                	cmp    %edx,%esi
f010359e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035a2:	89 d1                	mov    %edx,%ecx
f01035a4:	89 c3                	mov    %eax,%ebx
f01035a6:	72 08                	jb     f01035b0 <__umoddi3+0x110>
f01035a8:	75 11                	jne    f01035bb <__umoddi3+0x11b>
f01035aa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01035ae:	73 0b                	jae    f01035bb <__umoddi3+0x11b>
f01035b0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01035b4:	1b 14 24             	sbb    (%esp),%edx
f01035b7:	89 d1                	mov    %edx,%ecx
f01035b9:	89 c3                	mov    %eax,%ebx
f01035bb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01035bf:	29 da                	sub    %ebx,%edx
f01035c1:	19 ce                	sbb    %ecx,%esi
f01035c3:	89 f9                	mov    %edi,%ecx
f01035c5:	89 f0                	mov    %esi,%eax
f01035c7:	d3 e0                	shl    %cl,%eax
f01035c9:	89 e9                	mov    %ebp,%ecx
f01035cb:	d3 ea                	shr    %cl,%edx
f01035cd:	89 e9                	mov    %ebp,%ecx
f01035cf:	d3 ee                	shr    %cl,%esi
f01035d1:	09 d0                	or     %edx,%eax
f01035d3:	89 f2                	mov    %esi,%edx
f01035d5:	83 c4 1c             	add    $0x1c,%esp
f01035d8:	5b                   	pop    %ebx
f01035d9:	5e                   	pop    %esi
f01035da:	5f                   	pop    %edi
f01035db:	5d                   	pop    %ebp
f01035dc:	c3                   	ret    
f01035dd:	8d 76 00             	lea    0x0(%esi),%esi
f01035e0:	29 f9                	sub    %edi,%ecx
f01035e2:	19 d6                	sbb    %edx,%esi
f01035e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035ec:	e9 18 ff ff ff       	jmp    f0103509 <__umoddi3+0x69>
