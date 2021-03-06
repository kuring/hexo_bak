---
title: Linux信号机制学习
Status: public
url: linux_signal
tags: Linux
date: 2014-12-22
---

[TOC]

信号机制在Linux编程中一直是一个难点，因为信号往往跟进程、线程、定时器、I/O等多个层面都有牵涉，这些情况存在错综复杂的关系，堪比娱乐圈错综复杂的男女关系，要想全面理解信号机制确实不易。

# 信号种类

在Linux中可以通过如下命令来查看所有的信号：

```
[kuring@localhost ~]$ kill -l
 1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL       5) SIGTRAP
 6) SIGABRT      7) SIGBUS       8) SIGFPE       9) SIGKILL     10) SIGUSR1
11) SIGSEGV     12) SIGUSR2     13) SIGPIPE     14) SIGALRM     15) SIGTERM
16) SIGSTKFLT   17) SIGCHLD     18) SIGCONT     19) SIGSTOP     20) SIGTSTP
21) SIGTTIN     22) SIGTTOU     23) SIGURG      24) SIGXCPU     25) SIGXFSZ
26) SIGVTALRM   27) SIGPROF     28) SIGWINCH    29) SIGIO       30) SIGPWR
31) SIGSYS      34) SIGRTMIN    35) SIGRTMIN+1  36) SIGRTMIN+2  37) SIGRTMIN+3
38) SIGRTMIN+4  39) SIGRTMIN+5  40) SIGRTMIN+6  41) SIGRTMIN+7  42) SIGRTMIN+8
43) SIGRTMIN+9  44) SIGRTMIN+10 45) SIGRTMIN+11 46) SIGRTMIN+12 47) SIGRTMIN+13
48) SIGRTMIN+14 49) SIGRTMIN+15 50) SIGRTMAX-14 51) SIGRTMAX-13 52) SIGRTMAX-12
53) SIGRTMAX-11 54) SIGRTMAX-10 55) SIGRTMAX-9  56) SIGRTMAX-8  57) SIGRTMAX-7
58) SIGRTMAX-6  59) SIGRTMAX-5  60) SIGRTMAX-4  61) SIGRTMAX-3  62) SIGRTMAX-2
63) SIGRTMAX-1  64) SIGRTMAX
```

共64个信号，分为两种信号：非实时信号和实时信号。其中1-31个信号为非实时信号，32-64为实时信号。

当一信号在阻塞状态下产生多次信号，当解除该信号的阻塞后，非实时信号仅传递一次信号，而实时信号会传递多次。

对于非实时信号：内核会为每个信号维护一个信号掩码，并阻塞信号针对该进程的传递。如果将阻塞的信号发送给某进程，对该信号的传递将延时，直至从进程掩码中移除该信号为止。当从进程掩码中移除该信号时该信号将传递给该进程。如果信号在阻塞期间传递过多次该信号，信号解除阻塞后仅传递一次。

对于实时信号：实时信号采用队列化处理，一个实时信号的多个实例发送给进程，信号将会传递多次。可以制定伴随数据，用于产生信号时的数据传递。不同实时信号的传递顺序是固定的，优先传递信号编号小的。

# 信号阻塞

内核会为每个信号维护一个信号掩码，来阻塞内核将信号传递给该进程。如果将阻塞的信号发送给该进程，信号的传递将延后，从进程信号掩码中移除该信号后内核立刻将信号传递给该进程。如果一个信号在阻塞状态下产生多次，对于非实时信号稍后仅会传递一次，对于实时信号内核会进行排队处理，会传递多次。

# 信号处理函数

要想在进程中设置信号处理函数有两种选择：signal()和sigaction()。其中signal()函数提供的接口比较简单，但是在不同的UNIX系统之间存在差异，跨平台特性不是很好,signal()函数由于是C库函数，实现往往是采用sigaction()系统调用完成。sigaction()具有很好的跨平台性，但是使用较为复杂，但是却可以在信号处理程序中完成阻塞信号的作用。

在sigaction函数中可以指定调用信号处理函数时要阻塞的信号集，不允许这些信号中断信号处理函数的调用，直到信号处理函数调用完毕后信号才会传递。这一点通过signal函数是完不成的，利用signal函数设定的信号处理函数只能在信号处理函数开始时使用sigprocmask设置要阻塞的信号，在信号处理函数尾部利用sigprocmask还原信号，但在调用第一次调用sigprocmask函数之前和第二次调用sigprocmask函数之后的空白期内却无法防止要阻塞信号的传递。

信号处理函数中调用的函数尽量是异步信号安全的，C库中的函数不是异步信号安全的函数。

在信号处理函数中尽量避免访问全局变量，要访问全局变量可以使用`volatile sig_atomic_t flag`，volatile防止将编译器将变量优化到内存中，sig_atomic_t是一种整形数据类型，用来保证读写操作的原子性。

# 系统调用的中断

当系统调用阻塞时，之前创建了处理函数的信号传递过来。在信号处理函数返回后，默认情况下，系统调用会失败，并将errno置为EINTR。

如果调用指定了SA_RESTART标志的sigaction()函数来创建信号处理器函数，内核会在信号处理函数返回后自动重启系统调用，从而避免了信号处理函数对阻塞的系统调用产生的影响。比较不幸的是，并非所有的系统调用都支持该特性。

# 信号的同步生成和异步生成

这里的同步是对信号产生方式的描述，跟具体哪个信号无关。所有的信号均可同步生成，也可异步生成。

异步生成：引发信号产生的事件与进程的执行无关。例如，用户输入了中断字符、子进程终止等事件，这些信号的产生该进程是无法左右的。

同步生成：当执行特定的机制指令产生硬件异常时或进程使用raise()、kill()等向自身发生信号时，信号是同步传递的。这些信号的产生时间该进程是可以左右的。

# 信号传递的时机和顺序

同步产生的信号会立即传递给该进程。例如，当使用raise()函数向自身发送信号时，信号会在raise()调用前发生。

异步产生一个信号时，且在进程并未阻塞的情况下，信号也不会立即被传递。当且仅当进程正在执行，并且由内核态到用户态的下一次切换时才会传递信号。说人话就是在以下两种情况下会传递信号：进程获得调度时和系统调用完成时。这是因为内核会在进程在内核态和用户态进行的切换的时候才会检测信号。

非实时信号的传递顺序无法保障，实时信号的传递顺序是固定的，当多个不同的实时信号处于等待状态时，优先传递最小编号的信号。

# 信号和线程

信号模型是基于进程模型而设计的，应尽量避免在多线程中使用信号模型。

信号的发送可以针对整个进程，也可以针对特定线程。

当进程收到一个信号后，内核会任选一个线程来接收信号，并调用信号处理函数对信号进行处理。

每个线程可以独立设置信号掩码。

如果信号处理程序中断了对pthread_mutex_lock()和pthread_cond_wait()的调用，该调用会自动重启。

# 参考文章

《Linux/Unix系统编程手册》
