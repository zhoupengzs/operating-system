# mit-6.828-lab3
## Exercise1
```
//mem_init()
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
    envs = (struct Env*)boot_alloc(ROUNDUP(NENV * sizeof(struct Env), PGSIZE));
```
## Exercise2
### env_init()
```
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.

    int temp = 0;
    env_free_list = NULL;
    cprintf("NENV -1 : %u\n", NENV -1);

    for (temp = NENV -1; temp >= 0; temp--)
    {
        envs[temp].env_id = 0;
        envs[temp].env_parent_id = 0;
        envs[temp].env_type = ENV_TYPE_USER;
        envs[temp].env_status = ENV_FREE;
        envs[temp].env_runs = 0;
        envs[temp].env_pgdir = NULL;
        envs[temp].env_link = env_free_list;
        env_free_list = &envs[temp];
    }

    cprintf("env_free_list : 0x%08x, & envs[temp]: 0x%08x\n", env_free_list, &envs[temp]);

	// Per-CPU part of the initialization
	env_init_percpu();
}
```
### env_setup_vm()
```
// LAB 3: Your code here.
    (p->pp_ref)++;
    pde_t* page_dir = page2kva(p);
    memcpy(page_dir, kern_pgdir, PGSIZE);
    e->env_pgdir = page_dir;

```
### region_alloc()
```
static void
region_alloc(struct Env *e, void *va, size_t len)
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)

    va = ROUNDDOWN(va, PGSIZE);
    len = ROUNDUP(len, PGSIZE);

    struct PageInfo *pp;
    int ret = 0;

    for(; len > 0; len -= PGSIZE, va += PGSIZE)
    {
        pp = page_alloc(0);

        if(!pp)
        {
            panic("region_alloc failed\n");
        }

        ret = page_insert(e->env_pgdir, pp, va, PTE_U | PTE_W | PTE_P);

        if(ret)
        {
            panic("region_alloc failed\n");
        }
    }
}
```
### load_icode()
```
static void
load_icode(struct Env *e, uint8_t * binary)
{
	// Hints:
	//  Load each program segment into virtual memory
	//  at the address specified in the ELF section header.
	//  You should only load segments with ph->p_type == ELF_PROG_LOAD.
	//  Each segment's virtual address can be found in ph->p_va
	//  and its size in memory can be found in ph->p_memsz.
	//  The ph->p_filesz bytes from the ELF binary, starting at
	//  'binary + ph->p_offset', should be copied to virtual address
	//  ph->p_va.  Any remaining memory bytes should be cleared to zero.
	//  (The ELF header should have ph->p_filesz <= ph->p_memsz.)
	//  Use functions from the previous lab to allocate and map pages.
	//
	//  All page protection bits should be user read/write for now.
	//  ELF segments are not necessarily page-aligned, but you can
	//  assume for this function that no two segments will touch
	//  the same virtual page.
	//
	//  You may find a function like region_alloc useful.
	//
	//  Loading the segments is much simpler if you can move data
	//  directly into the virtual addresses stored in the ELF binary.
	//  So which page directory should be in force during
	//  this function?
	//
	//  You must also do something with the program's entry point,
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.

    struct Elf* elfhdr = (struct Elf *)binary;
    struct Proghdr *ph, *eph;
    
    if(elfhdr->e_magic != ELF_MAGIC)
    {
        panic("elf header's magic is not correct\n");
    }

    ph = (struct Proghdr *)((uint8_t *)elfhdr + elfhdr->e_phoff);

    eph = ph + elfhdr->e_phnum;

    lcr3(PADDR(e->env_pgdir));

    for(;ph < eph; ph++)
    {
        if(ph->p_type != ELF_PROG_LOAD)
        {
            continue;
        }

        if(ph->p_filesz > ph->p_memsz)
        {
            panic("file size is great than memory size\n");
        }

        region_alloc(e, (void *)ph->p_va, ph->p_memsz);
        memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);

        memset((void *)ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
    }

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

    lcr3(PADDR(kern_pgdir));

    e->env_tf.tf_eip = elfhdr->e_entry;

    region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
}

```
### env_create()
```
void
env_create(uint8_t *binary, enum EnvType type)
{
	// LAB 3: Your code here.
    int ret = 0;
    struct Env *e = NULL;
    ret = env_alloc(&e, 0);

    if(ret < 0)
    {
        panic("env_create: %e\n", ret);
    }

    load_icode(e, binary);
    e->env_type = type;
}
```
### env_run()
```
void
env_run(struct Env *e)
{
	// Step 1: If this is a context switch (a new environment is running):
	//	   1. Set the current environment (if any) back to
	//	      ENV_RUNNABLE if it is ENV_RUNNING (think about
	//	      what other states it can be in),
	//	   2. Set 'curenv' to the new environment,
	//	   3. Set its status to ENV_RUNNING,
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.

	// Hint: This function loads the new environment's state from
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//panic("env_run not yet implemented");

    if(curenv && curenv->env_status == ENV_RUNNING)
    {
        curenv->env_status = ENV_RUNNABLE;
    }

    curenv = e;
    e->env_status = ENV_RUNNING;
    e->env_runs++;

    lcr3(PADDR(e->env_pgdir));

    env_pop_tf(&(e->env_tf));
}
```
## Exercise4~10
### trapentry.S
```
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

	TRAPHANDLER_NOEC(divide_error, T_DIVIDE)				# divide error
	TRAPHANDLER_NOEC(debug, T_DEBUG)						# debug exception
	TRAPHANDLER_NOEC(nmi, T_NMI)							# non-maskable interrupt
    TRAPHANDLER_NOEC(breakpoint, T_BRKPT)					# breakpoint
	TRAPHANDLER_NOEC(overflow, T_OFLOW)						# overflow
	TRAPHANDLER_NOEC(bounds, T_BOUND)						# bounds check
	TRAPHANDLER_NOEC(invalid_op, T_ILLOP)					# illegal opcode
	TRAPHANDLER_NOEC(device_not_available, T_DEVICE)		# device not available
	TRAPHANDLER(double_fault, T_DBLFLT)						# double fault
	TRAPHANDLER_NOEC(coprocessor_segment_overrun, T_COPROC)	# reserved (not generated by recent processors)
	TRAPHANDLER(invalid_TSS, T_TSS)							# invalid task switch segment
	TRAPHANDLER(segment_not_present, T_SEGNP)				# segment not present
	TRAPHANDLER(stack_segment, T_STACK)						# stack exception
	TRAPHANDLER(general_protection, T_GPFLT)				# general protection fault
	TRAPHANDLER(page_fault, T_PGFLT)						# page fault
	TRAPHANDLER_NOEC(reserved, T_RES)						# reserved
	TRAPHANDLER_NOEC(float_point_error, T_FPERR)			# floating point error
	TRAPHANDLER(alignment_check, T_ALIGN)					# alignment check
	TRAPHANDLER_NOEC(machine_check, T_MCHK)					# machine check
	TRAPHANDLER_NOEC(SIMD_float_point_error, T_SIMDERR)		# SIMD floating point error
	TRAPHANDLER_NOEC(trap_handler_placeholder20,20)
	TRAPHANDLER_NOEC(trap_handler_placeholder21,21)
	TRAPHANDLER_NOEC(trap_handler_placeholder22,22)
	TRAPHANDLER_NOEC(trap_handler_placeholder23,23)
	TRAPHANDLER_NOEC(trap_handler_placeholder24,24)
	TRAPHANDLER_NOEC(trap_handler_placeholder25,25)
	TRAPHANDLER_NOEC(trap_handler_placeholder26,26)
	TRAPHANDLER_NOEC(trap_handler_placeholder27,27)
	TRAPHANDLER_NOEC(trap_handler_placeholder28,28)
	TRAPHANDLER_NOEC(trap_handler_placeholder29,29)
	TRAPHANDLER_NOEC(trap_handler_placeholder30,30)
	TRAPHANDLER_NOEC(trap_handler_placeholder31,31)
	TRAPHANDLER_NOEC(trap_handler_placeholder32,32)
	TRAPHANDLER_NOEC(trap_handler_placeholder33,33)
	TRAPHANDLER_NOEC(trap_handler_placeholder34,34)
	TRAPHANDLER_NOEC(trap_handler_placeholder35,35)
	TRAPHANDLER_NOEC(trap_handler_placeholder36,36)
	TRAPHANDLER_NOEC(trap_handler_placeholder37,37)
	TRAPHANDLER_NOEC(trap_handler_placeholder38,38)
	TRAPHANDLER_NOEC(trap_handler_placeholder39,39)
	TRAPHANDLER_NOEC(trap_handler_placeholder40,40)
	TRAPHANDLER_NOEC(trap_handler_placeholder41,41)
	TRAPHANDLER_NOEC(trap_handler_placeholder42,42)
	TRAPHANDLER_NOEC(trap_handler_placeholder43,43)
	TRAPHANDLER_NOEC(trap_handler_placeholder44,44)
	TRAPHANDLER_NOEC(trap_handler_placeholder45,45)
	TRAPHANDLER_NOEC(trap_handler_placeholder46,46)
	TRAPHANDLER_NOEC(trap_handler_placeholder47,47)
	TRAPHANDLER_NOEC(system_call, T_SYSCALL)				# system call
	TRAPHANDLER_NOEC(trap_handler_placeholder49,49)
	TRAPHANDLER_NOEC(trap_handler_placeholder50,50)
	TRAPHANDLER_NOEC(trap_handler_placeholder51,51)
	TRAPHANDLER_NOEC(trap_handler_placeholder52,52)
	TRAPHANDLER_NOEC(trap_handler_placeholder53,53)
	TRAPHANDLER_NOEC(trap_handler_placeholder54,54)
	TRAPHANDLER_NOEC(trap_handler_placeholder55,55)
	TRAPHANDLER_NOEC(trap_handler_placeholder56,56)
	TRAPHANDLER_NOEC(trap_handler_placeholder57,57)
	TRAPHANDLER_NOEC(trap_handler_placeholder58,58)
	TRAPHANDLER_NOEC(trap_handler_placeholder59,59)
	TRAPHANDLER_NOEC(trap_handler_placeholder60,60)
	TRAPHANDLER_NOEC(trap_handler_placeholder61,61)
	TRAPHANDLER_NOEC(trap_handler_placeholder62,62)
	TRAPHANDLER_NOEC(trap_handler_placeholder63,63)
	TRAPHANDLER_NOEC(trap_handler_placeholder64,64)
	TRAPHANDLER_NOEC(trap_handler_placeholder65,65)
	TRAPHANDLER_NOEC(trap_handler_placeholder66,66)
	TRAPHANDLER_NOEC(trap_handler_placeholder67,67)
	TRAPHANDLER_NOEC(trap_handler_placeholder68,68)
	TRAPHANDLER_NOEC(trap_handler_placeholder69,69)
	TRAPHANDLER_NOEC(trap_handler_placeholder70,70)
	TRAPHANDLER_NOEC(trap_handler_placeholder71,71)
	TRAPHANDLER_NOEC(trap_handler_placeholder72,72)
	TRAPHANDLER_NOEC(trap_handler_placeholder73,73)
	TRAPHANDLER_NOEC(trap_handler_placeholder74,74)
	TRAPHANDLER_NOEC(trap_handler_placeholder75,75)
	TRAPHANDLER_NOEC(trap_handler_placeholder76,76)
	TRAPHANDLER_NOEC(trap_handler_placeholder77,77)
	TRAPHANDLER_NOEC(trap_handler_placeholder78,78)
	TRAPHANDLER_NOEC(trap_handler_placeholder79,79)
	TRAPHANDLER_NOEC(trap_handler_placeholder80,80)
	TRAPHANDLER_NOEC(trap_handler_placeholder81,81)
	TRAPHANDLER_NOEC(trap_handler_placeholder82,82)
	TRAPHANDLER_NOEC(trap_handler_placeholder83,83)
	TRAPHANDLER_NOEC(trap_handler_placeholder84,84)
	TRAPHANDLER_NOEC(trap_handler_placeholder85,85)
	TRAPHANDLER_NOEC(trap_handler_placeholder86,86)
	TRAPHANDLER_NOEC(trap_handler_placeholder87,87)
	TRAPHANDLER_NOEC(trap_handler_placeholder88,88)
	TRAPHANDLER_NOEC(trap_handler_placeholder89,89)
	TRAPHANDLER_NOEC(trap_handler_placeholder90,90)
	TRAPHANDLER_NOEC(trap_handler_placeholder91,91)
	TRAPHANDLER_NOEC(trap_handler_placeholder92,92)
	TRAPHANDLER_NOEC(trap_handler_placeholder93,93)
	TRAPHANDLER_NOEC(trap_handler_placeholder94,94)
	TRAPHANDLER_NOEC(trap_handler_placeholder95,95)
	TRAPHANDLER_NOEC(trap_handler_placeholder96,96)
	TRAPHANDLER_NOEC(trap_handler_placeholder97,97)
	TRAPHANDLER_NOEC(trap_handler_placeholder98,98)
	TRAPHANDLER_NOEC(trap_handler_placeholder99,99)
	TRAPHANDLER_NOEC(trap_handler_placeholder100,100)
	TRAPHANDLER_NOEC(trap_handler_placeholder101,101)
	TRAPHANDLER_NOEC(trap_handler_placeholder102,102)
	TRAPHANDLER_NOEC(trap_handler_placeholder103,103)
	TRAPHANDLER_NOEC(trap_handler_placeholder104,104)
	TRAPHANDLER_NOEC(trap_handler_placeholder105,105)
	TRAPHANDLER_NOEC(trap_handler_placeholder106,106)
	TRAPHANDLER_NOEC(trap_handler_placeholder107,107)
	TRAPHANDLER_NOEC(trap_handler_placeholder108,108)
	TRAPHANDLER_NOEC(trap_handler_placeholder109,109)
	TRAPHANDLER_NOEC(trap_handler_placeholder110,110)
	TRAPHANDLER_NOEC(trap_handler_placeholder111,111)
	TRAPHANDLER_NOEC(trap_handler_placeholder112,112)
	TRAPHANDLER_NOEC(trap_handler_placeholder113,113)
	TRAPHANDLER_NOEC(trap_handler_placeholder114,114)
	TRAPHANDLER_NOEC(trap_handler_placeholder115,115)
	TRAPHANDLER_NOEC(trap_handler_placeholder116,116)
	TRAPHANDLER_NOEC(trap_handler_placeholder117,117)
	TRAPHANDLER_NOEC(trap_handler_placeholder118,118)
	TRAPHANDLER_NOEC(trap_handler_placeholder119,119)
	TRAPHANDLER_NOEC(trap_handler_placeholder120,120)
	TRAPHANDLER_NOEC(trap_handler_placeholder121,121)
	TRAPHANDLER_NOEC(trap_handler_placeholder122,122)
	TRAPHANDLER_NOEC(trap_handler_placeholder123,123)
	TRAPHANDLER_NOEC(trap_handler_placeholder124,124)
	TRAPHANDLER_NOEC(trap_handler_placeholder125,125)
	TRAPHANDLER_NOEC(trap_handler_placeholder126,126)
	TRAPHANDLER_NOEC(trap_handler_placeholder127,127)
	TRAPHANDLER_NOEC(trap_handler_placeholder128,128)
	TRAPHANDLER_NOEC(trap_handler_placeholder129,129)
	TRAPHANDLER_NOEC(trap_handler_placeholder130,130)
	TRAPHANDLER_NOEC(trap_handler_placeholder131,131)
	TRAPHANDLER_NOEC(trap_handler_placeholder132,132)
	TRAPHANDLER_NOEC(trap_handler_placeholder133,133)
	TRAPHANDLER_NOEC(trap_handler_placeholder134,134)
	TRAPHANDLER_NOEC(trap_handler_placeholder135,135)
	TRAPHANDLER_NOEC(trap_handler_placeholder136,136)
	TRAPHANDLER_NOEC(trap_handler_placeholder137,137)
	TRAPHANDLER_NOEC(trap_handler_placeholder138,138)
	TRAPHANDLER_NOEC(trap_handler_placeholder139,139)
	TRAPHANDLER_NOEC(trap_handler_placeholder140,140)
	TRAPHANDLER_NOEC(trap_handler_placeholder141,141)
	TRAPHANDLER_NOEC(trap_handler_placeholder142,142)
	TRAPHANDLER_NOEC(trap_handler_placeholder143,143)
	TRAPHANDLER_NOEC(trap_handler_placeholder144,144)
	TRAPHANDLER_NOEC(trap_handler_placeholder145,145)
	TRAPHANDLER_NOEC(trap_handler_placeholder146,146)
	TRAPHANDLER_NOEC(trap_handler_placeholder147,147)
	TRAPHANDLER_NOEC(trap_handler_placeholder148,148)
	TRAPHANDLER_NOEC(trap_handler_placeholder149,149)
	TRAPHANDLER_NOEC(trap_handler_placeholder150,150)
	TRAPHANDLER_NOEC(trap_handler_placeholder151,151)
	TRAPHANDLER_NOEC(trap_handler_placeholder152,152)
	TRAPHANDLER_NOEC(trap_handler_placeholder153,153)
	TRAPHANDLER_NOEC(trap_handler_placeholder154,154)
	TRAPHANDLER_NOEC(trap_handler_placeholder155,155)
	TRAPHANDLER_NOEC(trap_handler_placeholder156,156)
	TRAPHANDLER_NOEC(trap_handler_placeholder157,157)
	TRAPHANDLER_NOEC(trap_handler_placeholder158,158)
	TRAPHANDLER_NOEC(trap_handler_placeholder159,159)
	TRAPHANDLER_NOEC(trap_handler_placeholder160,160)
	TRAPHANDLER_NOEC(trap_handler_placeholder161,161)
	TRAPHANDLER_NOEC(trap_handler_placeholder162,162)
	TRAPHANDLER_NOEC(trap_handler_placeholder163,163)
	TRAPHANDLER_NOEC(trap_handler_placeholder164,164)
	TRAPHANDLER_NOEC(trap_handler_placeholder165,165)
	TRAPHANDLER_NOEC(trap_handler_placeholder166,166)
	TRAPHANDLER_NOEC(trap_handler_placeholder167,167)
	TRAPHANDLER_NOEC(trap_handler_placeholder168,168)
	TRAPHANDLER_NOEC(trap_handler_placeholder169,169)
	TRAPHANDLER_NOEC(trap_handler_placeholder170,170)
	TRAPHANDLER_NOEC(trap_handler_placeholder171,171)
	TRAPHANDLER_NOEC(trap_handler_placeholder172,172)
	TRAPHANDLER_NOEC(trap_handler_placeholder173,173)
	TRAPHANDLER_NOEC(trap_handler_placeholder174,174)
	TRAPHANDLER_NOEC(trap_handler_placeholder175,175)
	TRAPHANDLER_NOEC(trap_handler_placeholder176,176)
	TRAPHANDLER_NOEC(trap_handler_placeholder177,177)
	TRAPHANDLER_NOEC(trap_handler_placeholder178,178)
	TRAPHANDLER_NOEC(trap_handler_placeholder179,179)
	TRAPHANDLER_NOEC(trap_handler_placeholder180,180)
	TRAPHANDLER_NOEC(trap_handler_placeholder181,181)
	TRAPHANDLER_NOEC(trap_handler_placeholder182,182)
	TRAPHANDLER_NOEC(trap_handler_placeholder183,183)
	TRAPHANDLER_NOEC(trap_handler_placeholder184,184)
	TRAPHANDLER_NOEC(trap_handler_placeholder185,185)
	TRAPHANDLER_NOEC(trap_handler_placeholder186,186)
	TRAPHANDLER_NOEC(trap_handler_placeholder187,187)
	TRAPHANDLER_NOEC(trap_handler_placeholder188,188)
	TRAPHANDLER_NOEC(trap_handler_placeholder189,189)
	TRAPHANDLER_NOEC(trap_handler_placeholder190,190)
	TRAPHANDLER_NOEC(trap_handler_placeholder191,191)
	TRAPHANDLER_NOEC(trap_handler_placeholder192,192)
	TRAPHANDLER_NOEC(trap_handler_placeholder193,193)
	TRAPHANDLER_NOEC(trap_handler_placeholder194,194)
	TRAPHANDLER_NOEC(trap_handler_placeholder195,195)
	TRAPHANDLER_NOEC(trap_handler_placeholder196,196)
	TRAPHANDLER_NOEC(trap_handler_placeholder197,197)
	TRAPHANDLER_NOEC(trap_handler_placeholder198,198)
	TRAPHANDLER_NOEC(trap_handler_placeholder199,199)
	TRAPHANDLER_NOEC(trap_handler_placeholder200,200)
	TRAPHANDLER_NOEC(trap_handler_placeholder201,201)
	TRAPHANDLER_NOEC(trap_handler_placeholder202,202)
	TRAPHANDLER_NOEC(trap_handler_placeholder203,203)
	TRAPHANDLER_NOEC(trap_handler_placeholder204,204)
	TRAPHANDLER_NOEC(trap_handler_placeholder205,205)
	TRAPHANDLER_NOEC(trap_handler_placeholder206,206)
	TRAPHANDLER_NOEC(trap_handler_placeholder207,207)
	TRAPHANDLER_NOEC(trap_handler_placeholder208,208)
	TRAPHANDLER_NOEC(trap_handler_placeholder209,209)
	TRAPHANDLER_NOEC(trap_handler_placeholder210,210)
	TRAPHANDLER_NOEC(trap_handler_placeholder211,211)
	TRAPHANDLER_NOEC(trap_handler_placeholder212,212)
	TRAPHANDLER_NOEC(trap_handler_placeholder213,213)
	TRAPHANDLER_NOEC(trap_handler_placeholder214,214)
	TRAPHANDLER_NOEC(trap_handler_placeholder215,215)
	TRAPHANDLER_NOEC(trap_handler_placeholder216,216)
	TRAPHANDLER_NOEC(trap_handler_placeholder217,217)
	TRAPHANDLER_NOEC(trap_handler_placeholder218,218)
	TRAPHANDLER_NOEC(trap_handler_placeholder219,219)
	TRAPHANDLER_NOEC(trap_handler_placeholder220,220)
	TRAPHANDLER_NOEC(trap_handler_placeholder221,221)
	TRAPHANDLER_NOEC(trap_handler_placeholder222,222)
	TRAPHANDLER_NOEC(trap_handler_placeholder223,223)
	TRAPHANDLER_NOEC(trap_handler_placeholder224,224)
	TRAPHANDLER_NOEC(trap_handler_placeholder225,225)
	TRAPHANDLER_NOEC(trap_handler_placeholder226,226)
	TRAPHANDLER_NOEC(trap_handler_placeholder227,227)
	TRAPHANDLER_NOEC(trap_handler_placeholder228,228)
	TRAPHANDLER_NOEC(trap_handler_placeholder229,229)
	TRAPHANDLER_NOEC(trap_handler_placeholder230,230)
	TRAPHANDLER_NOEC(trap_handler_placeholder231,231)
	TRAPHANDLER_NOEC(trap_handler_placeholder232,232)
	TRAPHANDLER_NOEC(trap_handler_placeholder233,233)
	TRAPHANDLER_NOEC(trap_handler_placeholder234,234)
	TRAPHANDLER_NOEC(trap_handler_placeholder235,235)
	TRAPHANDLER_NOEC(trap_handler_placeholder236,236)
	TRAPHANDLER_NOEC(trap_handler_placeholder237,237)
	TRAPHANDLER_NOEC(trap_handler_placeholder238,238)
	TRAPHANDLER_NOEC(trap_handler_placeholder239,239)
	TRAPHANDLER_NOEC(trap_handler_placeholder240,240)
	TRAPHANDLER_NOEC(trap_handler_placeholder241,241)
	TRAPHANDLER_NOEC(trap_handler_placeholder242,242)
	TRAPHANDLER_NOEC(trap_handler_placeholder243,243)
	TRAPHANDLER_NOEC(trap_handler_placeholder244,244)
	TRAPHANDLER_NOEC(trap_handler_placeholder245,245)
	TRAPHANDLER_NOEC(trap_handler_placeholder246,246)
	TRAPHANDLER_NOEC(trap_handler_placeholder247,247)
	TRAPHANDLER_NOEC(trap_handler_placeholder248,248)
	TRAPHANDLER_NOEC(trap_handler_placeholder249,249)
	TRAPHANDLER_NOEC(trap_handler_placeholder250,250)
	TRAPHANDLER_NOEC(trap_handler_placeholder251,251)
	TRAPHANDLER_NOEC(trap_handler_placeholder252,252)
	TRAPHANDLER_NOEC(trap_handler_placeholder253,253)
	TRAPHANDLER_NOEC(trap_handler_placeholder254,254)
	TRAPHANDLER_NOEC(trap_handler_placeholder255,255)

//	TRAPHANDLER_NOEC(trap_default, T_DEFAULT)

.data
.globl idt_entries
idt_entries:
  .long divide_error
  .long debug
  .long nmi
  .long breakpoint
  .long overflow
  .long bounds
  .long invalid_op
  .long device_not_available
  .long double_fault
  .long coprocessor_segment_overrun
  .long invalid_TSS
  .long segment_not_present
  .long stack_segment
  .long general_protection
  .long page_fault
  .long reserved
  .long float_point_error
  .long alignment_check
  .long machine_check
  .long SIMD_float_point_error
  .long trap_handler_placeholder20
  .long trap_handler_placeholder21
  .long trap_handler_placeholder22
  .long trap_handler_placeholder23
  .long trap_handler_placeholder24
  .long trap_handler_placeholder25
  .long trap_handler_placeholder26
  .long trap_handler_placeholder27
  .long trap_handler_placeholder28
  .long trap_handler_placeholder29
  .long trap_handler_placeholder30
  .long trap_handler_placeholder31
  .long trap_handler_placeholder32
  .long trap_handler_placeholder33
  .long trap_handler_placeholder34
  .long trap_handler_placeholder35
  .long trap_handler_placeholder36
  .long trap_handler_placeholder37
  .long trap_handler_placeholder38
  .long trap_handler_placeholder39
  .long trap_handler_placeholder40
  .long trap_handler_placeholder41
  .long trap_handler_placeholder42
  .long trap_handler_placeholder43
  .long trap_handler_placeholder44
  .long trap_handler_placeholder45
  .long trap_handler_placeholder46
  .long trap_handler_placeholder47
  .long system_call
  .long trap_handler_placeholder49
  .long trap_handler_placeholder50
  .long trap_handler_placeholder51
  .long trap_handler_placeholder52
  .long trap_handler_placeholder53
  .long trap_handler_placeholder54
  .long trap_handler_placeholder55
  .long trap_handler_placeholder56
  .long trap_handler_placeholder57
  .long trap_handler_placeholder58
  .long trap_handler_placeholder59
  .long trap_handler_placeholder60
  .long trap_handler_placeholder61
  .long trap_handler_placeholder62
  .long trap_handler_placeholder63
  .long trap_handler_placeholder64
  .long trap_handler_placeholder65
  .long trap_handler_placeholder66
  .long trap_handler_placeholder67
  .long trap_handler_placeholder68
  .long trap_handler_placeholder69
  .long trap_handler_placeholder70
  .long trap_handler_placeholder71
  .long trap_handler_placeholder72
  .long trap_handler_placeholder73
  .long trap_handler_placeholder74
  .long trap_handler_placeholder75
  .long trap_handler_placeholder76
  .long trap_handler_placeholder77
  .long trap_handler_placeholder78
  .long trap_handler_placeholder79
  .long trap_handler_placeholder80
  .long trap_handler_placeholder81
  .long trap_handler_placeholder82
  .long trap_handler_placeholder83
  .long trap_handler_placeholder84
  .long trap_handler_placeholder85
  .long trap_handler_placeholder86
  .long trap_handler_placeholder87
  .long trap_handler_placeholder88
  .long trap_handler_placeholder89
  .long trap_handler_placeholder90
  .long trap_handler_placeholder91
  .long trap_handler_placeholder92
  .long trap_handler_placeholder93
  .long trap_handler_placeholder94
  .long trap_handler_placeholder95
  .long trap_handler_placeholder96
  .long trap_handler_placeholder97
  .long trap_handler_placeholder98
  .long trap_handler_placeholder99
  .long trap_handler_placeholder100
  .long trap_handler_placeholder101
  .long trap_handler_placeholder102
  .long trap_handler_placeholder103
  .long trap_handler_placeholder104
  .long trap_handler_placeholder105
  .long trap_handler_placeholder106
  .long trap_handler_placeholder107
  .long trap_handler_placeholder108
  .long trap_handler_placeholder109
  .long trap_handler_placeholder110
  .long trap_handler_placeholder111
  .long trap_handler_placeholder112
  .long trap_handler_placeholder113
  .long trap_handler_placeholder114
  .long trap_handler_placeholder115
  .long trap_handler_placeholder116
  .long trap_handler_placeholder117
  .long trap_handler_placeholder118
  .long trap_handler_placeholder119
  .long trap_handler_placeholder120
  .long trap_handler_placeholder121
  .long trap_handler_placeholder122
  .long trap_handler_placeholder123
  .long trap_handler_placeholder124
  .long trap_handler_placeholder125
  .long trap_handler_placeholder126
  .long trap_handler_placeholder127
  .long trap_handler_placeholder128
  .long trap_handler_placeholder129
  .long trap_handler_placeholder130
  .long trap_handler_placeholder131
  .long trap_handler_placeholder132
  .long trap_handler_placeholder133
  .long trap_handler_placeholder134
  .long trap_handler_placeholder135
  .long trap_handler_placeholder136
  .long trap_handler_placeholder137
  .long trap_handler_placeholder138
  .long trap_handler_placeholder139
  .long trap_handler_placeholder140
  .long trap_handler_placeholder141
  .long trap_handler_placeholder142
  .long trap_handler_placeholder143
  .long trap_handler_placeholder144
  .long trap_handler_placeholder145
  .long trap_handler_placeholder146
  .long trap_handler_placeholder147
  .long trap_handler_placeholder148
  .long trap_handler_placeholder149
  .long trap_handler_placeholder150
  .long trap_handler_placeholder151
  .long trap_handler_placeholder152
  .long trap_handler_placeholder153
  .long trap_handler_placeholder154
  .long trap_handler_placeholder155
  .long trap_handler_placeholder156
  .long trap_handler_placeholder157
  .long trap_handler_placeholder158
  .long trap_handler_placeholder159
  .long trap_handler_placeholder160
  .long trap_handler_placeholder161
  .long trap_handler_placeholder162
  .long trap_handler_placeholder163
  .long trap_handler_placeholder164
  .long trap_handler_placeholder165
  .long trap_handler_placeholder166
  .long trap_handler_placeholder167
  .long trap_handler_placeholder168
  .long trap_handler_placeholder169
  .long trap_handler_placeholder170
  .long trap_handler_placeholder171
  .long trap_handler_placeholder172
  .long trap_handler_placeholder173
  .long trap_handler_placeholder174
  .long trap_handler_placeholder175
  .long trap_handler_placeholder176
  .long trap_handler_placeholder177
  .long trap_handler_placeholder178
  .long trap_handler_placeholder179
  .long trap_handler_placeholder180
  .long trap_handler_placeholder181
  .long trap_handler_placeholder182
  .long trap_handler_placeholder183
  .long trap_handler_placeholder184
  .long trap_handler_placeholder185
  .long trap_handler_placeholder186
  .long trap_handler_placeholder187
  .long trap_handler_placeholder188
  .long trap_handler_placeholder189
  .long trap_handler_placeholder190
  .long trap_handler_placeholder191
  .long trap_handler_placeholder192
  .long trap_handler_placeholder193
  .long trap_handler_placeholder194
  .long trap_handler_placeholder195
  .long trap_handler_placeholder196
  .long trap_handler_placeholder197
  .long trap_handler_placeholder198
  .long trap_handler_placeholder199
  .long trap_handler_placeholder200
  .long trap_handler_placeholder201
  .long trap_handler_placeholder202
  .long trap_handler_placeholder203
  .long trap_handler_placeholder204
  .long trap_handler_placeholder205
  .long trap_handler_placeholder206
  .long trap_handler_placeholder207
  .long trap_handler_placeholder208
  .long trap_handler_placeholder209
  .long trap_handler_placeholder210
  .long trap_handler_placeholder211
  .long trap_handler_placeholder212
  .long trap_handler_placeholder213
  .long trap_handler_placeholder214
  .long trap_handler_placeholder215
  .long trap_handler_placeholder216
  .long trap_handler_placeholder217
  .long trap_handler_placeholder218
  .long trap_handler_placeholder219
  .long trap_handler_placeholder220
  .long trap_handler_placeholder221
  .long trap_handler_placeholder222
  .long trap_handler_placeholder223
  .long trap_handler_placeholder224
  .long trap_handler_placeholder225
  .long trap_handler_placeholder226
  .long trap_handler_placeholder227
  .long trap_handler_placeholder228
  .long trap_handler_placeholder229
  .long trap_handler_placeholder230
  .long trap_handler_placeholder231
  .long trap_handler_placeholder232
  .long trap_handler_placeholder233
  .long trap_handler_placeholder234
  .long trap_handler_placeholder235
  .long trap_handler_placeholder236
  .long trap_handler_placeholder237
  .long trap_handler_placeholder238
  .long trap_handler_placeholder239
  .long trap_handler_placeholder240
  .long trap_handler_placeholder241
  .long trap_handler_placeholder242
  .long trap_handler_placeholder243
  .long trap_handler_placeholder244
  .long trap_handler_placeholder245
  .long trap_handler_placeholder246
  .long trap_handler_placeholder247
  .long trap_handler_placeholder248
  .long trap_handler_placeholder249
  .long trap_handler_placeholder250
  .long trap_handler_placeholder251
  .long trap_handler_placeholder252
  .long trap_handler_placeholder253
  .long trap_handler_placeholder254
  .long trap_handler_placeholder255

/*
 * Lab 3: Your code here for _alltraps
 */
.text
.globl _alltraps
_alltraps:
  # Push values (in reverse) to make the stack look like a struct Trapframe
  # Everything below tf_trapno is already on stack
  pushl %ds
  pushl %es
  pushal
  # Looking back from stack top, we get exactly a struct Trapframe
  
  # load GD_KD into %ds and %es
  movl $GD_KD, %eax
  movw %ax,%ds
  movw %ax,%es

  # pushl %esp to pass a pointer to the Trapframe as an argument to trap()
  pushl %esp
  /* Nuke frame pointer, like we do in entry.S when bootstrapping kernel.
     Otherwise backtrace would walk off the stack. */  
  # avoid page fault in kernel
  movl $0, %ebp
  call trap

  # Clean up the stack setup for previous trap() call and prepare for iret
  addl $4, %esp       # skip the argument we passed on stack to trap()
  popal
  popl %es
  popl %ds
  addl $8, %esp       # skip trapno and errcode
  iret

```
### trap.c
```
//trap_init()
trap_init(void)
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

    extern uint32_t idt_entries[];
    int i = 0;
    for (i = 0; i < 256; i++)
    {
        switch(i)
        {
            case T_BRKPT:
            case T_SYSCALL:
                    SETGATE(idt[i], 0, GD_KT, idt_entries[i], 3);
                    break;

            default:
                    SETGATE(idt[i], 0, GD_KT, idt_entries[i], 0);
                    break;
        }
    }

    ts.ts_esp0 = KSTACKTOP;
    ts.ts_ss0  = GD_KD;

    gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts), sizeof(struct Taskstate), 0);
    gdt[GD_TSS0 >> 3].sd_s = 0;

    ltr(GD_TSS0);
	// Per-CPU setup 
	trap_init_percpu();
}
//trap_dispatch()
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

    switch(tf->tf_trapno)
    {
        case T_PGFLT:
                page_fault_handler(tf);
                return;
        case T_BRKPT:
                monitor(tf);
                return;

        case T_SYSCALL:
                tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
                            tf->tf_regs.reg_edx,
                            tf->tf_regs.reg_ecx,
                            tf->tf_regs.reg_ebx,
                            tf->tf_regs.reg_edi,
                            tf->tf_regs.reg_esi);
                return ;
                
    }
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
}
//page_fault_handler()
void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.

    if(tf->tf_cs == GD_KT)
    {
        panic("Page fault in kernel");
    }
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}
```
