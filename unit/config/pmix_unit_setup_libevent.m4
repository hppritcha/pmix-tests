# -*- shell-script -*-
#
# Copyright (c) 2009-2015 Cisco Systems, Inc.  All rights reserved.
# Copyright (c) 2013      Los Alamos National Security, LLC.  All rights reserved.
# Copyright (c) 2013-2019 Intel, Inc.  All rights reserved.
# Copyright (c) 2017-2019 Research Organization for Information Science
#                         and Technology (RIST).  All rights reserved.
# $COPYRIGHT$
#
# Additional copyrights may follow
#
# $HEADER$
#

# MCA_libevent_CONFIG([action-if-found], [action-if-not-found])
# --------------------------------------------------------------------
AC_DEFUN([PMIX_UNIT_LIBEVENT_CONFIG],[
    PMIX_UNIT_VAR_SCOPE_PUSH([pmix_unit_event_dir pmix_unit_event_libdir pmix_unit_event_defaults])

    AC_ARG_WITH([libevent-header],
                [AC_HELP_STRING([--with-libevent-header=HEADER],
                                [The value that should be included in C files to include event.h])])

    pmix_unit_libevent_support=0

    AC_ARG_WITH([libevent],
                [AC_HELP_STRING([--with-libevent=DIR],
                                [Search for libevent headers and libraries in DIR ])])

    AC_ARG_WITH([libevent-libdir],
                [AC_HELP_STRING([--with-libevent-libdir=DIR],
                                [Search for libevent libraries in DIR ])])

    pmix_unit_check_libevent_save_CPPFLAGS="$CPPFLAGS"
    pmix_unit_check_libevent_save_LDFLAGS="$LDFLAGS"
    pmix_unit_check_libevent_save_LIBS="$LIBS"

    # get rid of the trailing slash(es)
    libevent_prefix=$(echo $with_libevent | sed -e 'sX/*$XXg')
    libeventdir_prefix=$(echo $with_libevent_libdir | sed -e 'sX/*$XXg')

    if test "$libevent_prefix" != "no"; then
        AC_MSG_CHECKING([for libevent in])
        if test ! -z "$libevent_prefix" && test "$libevent_prefix" != "yes"; then
            pmix_unit_event_defaults=no
            pmix_unit_event_dir=$libevent_prefix/include
            if test -d $libevent_prefix/lib64; then
                pmix_unit_event_libdir=$libevent_prefix/lib64
            elif test -d $libevent_prefix/lib; then
                pmix_unit_event_libdir=$libevent_prefix/lib
            elif test -d $libevent_prefix; then
                pmix_unit_event_libdir=$libevent_prefix
            else
                AC_MSG_RESULT([Could not find $libevent_prefix/lib, $libevent_prefix/lib64, or $libevent_prefix])
                AC_MSG_ERROR([Can not continue])
            fi
            AC_MSG_RESULT([$pmix_unit_event_dir and $pmix_unit_event_libdir])
        else
            pmix_unit_event_defaults=yes
            pmix_unit_event_dir=/usr/include
            if test -d /usr/lib64; then
                pmix_unit_event_libdir=/usr/lib64
                AC_MSG_RESULT([(default search paths)])
            elif test -d /usr/lib; then
                pmix_unit_event_libdir=/usr/lib
                AC_MSG_RESULT([(default search paths)])
            else
                AC_MSG_RESULT([default paths not found])
                pmix_unit_libevent_support=0
            fi
        fi
        AS_IF([test ! -z "$libeventdir_prefix" && "$libeventdir_prefix" != "yes"],
              [pmix_unit_event_libdir="$libeventdir_prefix"])

        PMIX_UNIT_CHECK_PACKAGE([pmix_unit_libevent],
                           [event.h],
                           [event],
                           [event_config_new],
                           [-levent -levent_pthreads],
                           [$pmix_unit_event_dir],
                           [$pmix_unit_event_libdir],
                           [pmix_unit_libevent_support=1],
                           [pmix_unit_libevent_support=0])

        AS_IF([test "$pmix_unit_event_defaults" = "no"],
              [PMIX_UNIT_FLAGS_APPEND_UNIQ(CPPFLAGS, $pmix_unit_libevent_CPPFLAGS)
               PMIX_UNIT_FLAGS_APPEND_UNIQ(LDFLAGS, $pmix_unit_libevent_LDFLAGS)])
        PMIX_UNIT_FLAGS_APPEND_UNIQ(LIBS, $pmix_unit_libevent_LIBS)

        if test $pmix_unit_libevent_support -eq 1; then
            # Ensure that this libevent has the symbol
            # "evthread_set_lock_callbacks", which will only exist if
            # libevent was configured with thread support.
            AC_CHECK_LIB([event], [evthread_set_lock_callbacks],
                         [],
                         [AC_MSG_WARN([External libevent does not have thread support])
                          AC_MSG_WARN([PMIx_unit requires libevent to be compiled with])
                          AC_MSG_WARN([thread support enabled])
                          pmix_unit_libevent_support=0])
        fi
        if test $pmix_unit_libevent_support -eq 1; then
            AC_CHECK_LIB([event_pthreads], [evthread_use_pthreads],
                         [],
                         [AC_MSG_WARN([External libevent does not have thread support])
                          AC_MSG_WARN([PMIx_unit requires libevent to be compiled with])
                          AC_MSG_WARN([thread support enabled])
                          pmix_unit_libevent_support=0])
        fi
    fi

    CPPFLAGS="$pmix_unit_check_libevent_save_CPPFLAGS"
    LDFLAGS="$pmix_unit_check_libevent_save_LDFLAGS"
    LIBS="$pmix_unit_check_libevent_save_LIBS"

    AC_MSG_CHECKING([will libevent support be built])
    if test $pmix_unit_libevent_support -eq 1; then
        AC_MSG_RESULT([yes])
        # Set output variables
        PMIX_UNIT_EVENT_HEADER="<event.h>"
        PMIX_UNIT_EVENT2_THREAD_HEADER="<event2/thread.h>"
        AC_DEFINE_UNQUOTED([PMIX_UNIT_EVENT_HEADER], [$PMIX_UNIT_EVENT_HEADER],
                           [Location of event.h])
        pmix_unit_libevent_source=$pmix_unit_event_dir
        AS_IF([test "$pmix_unit_event_defaults" = "no"],
              [PMIX_UNIT_FLAGS_APPEND_UNIQ(CPPFLAGS, $pmix_unit_libevent_CPPFLAGS)
               PMIX_UNIT_FLAGS_APPEND_UNIQ(LDFLAGS, $pmix_unit_libevent_LDFLAGS)])
        PMIX_UNIT_FLAGS_APPEND_UNIQ(LIBS, $pmix_unit_libevent_LIBS)
    else
        AC_MSG_RESULT([no])
    fi

    if test $pmix_unit_libevent_support -eq 1; then
        AC_MSG_CHECKING([libevent header])
        AC_DEFINE_UNQUOTED([PMIX_UNIT_EVENT_HEADER], [$PMIX_UNIT_EVENT_HEADER],
                           [Location of event.h])
        AC_MSG_RESULT([$PMIX_UNIT_EVENT_HEADER])
        AC_MSG_CHECKING([libevent2/thread header])
        AC_DEFINE_UNQUOTED([PMIX_UNIT_EVENT2_THREAD_HEADER], [$PMIX_UNIT_EVENT2_THREAD_HEADER],
                           [Location of event2/thread.h])
        AC_MSG_RESULT([$PMIX_UNIT_EVENT2_THREAD_HEADER])
    fi

    AC_DEFINE_UNQUOTED([PMIX_UNIT_HAVE_LIBEVENT], [$pmix_unit_libevent_support], [Whether we are building against libevent])

    PMIX_UNIT_VAR_SCOPE_POP
])dnl