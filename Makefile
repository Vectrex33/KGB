#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

include $(DEVKITARM)/ds_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
# SPECS is the directory containing the important build and link files
#---------------------------------------------------------------------------------
TARGET 		:=  arm9loaderhax
BUILD		:=	build
SOURCES		:=	source
DATA		:=	data
INCLUDES	:=	source

NAME		:=  KGB
CHAIN		:=  chainloader
STAGE2		:=  stage2

CHAIN_H		:=  $(CURDIR)/$(SOURCES)/$(CHAIN).h

#---------------------------------------------------------------------------------
# Setup some defines
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	 :=	-marm -march=armv5te -mtune=arm946e-s

CFLAGS   := $(ARCH) \
			-g -flto -Wall -O2 \
			-fomit-frame-pointer -ffast-math \
			-std=c99

CFLAGS	 += $(INCLUDE) -DARM9
CFLAGS	 +=	-DBUILD_NAME="\"$(NAME) (`date +'%Y/%m/%d'`)\""

CXXFLAGS := $(CFLAGS) -fno-rtti -fno-exceptions

LDFLAGS  := -nostartfiles -T../linker.ld -g $(ARCH) -Wl,-Map,$(notdir $*.map)
ASFLAGS	 :=	-g $(ARCH)

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(CTRARM9)

#---------------------------------------------------------------------------------
# any extra libraries we wish to link with the project (order is important)
#---------------------------------------------------------------------------------
LIBS    := -lctr9


#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES	:= $(addsuffix .o,$(BINFILES)) \
			$(SFILES:.s=.o) $(CPPFILES:.cpp=.o) $(CFILES:.c=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: $(BUILD) all $(CHAIN) release clean

#---------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD): $(CHAIN_H)
	@[ -d $(OUTPUT_D) ] || mkdir -p $(OUTPUT_D)
	@[ -d $(BUILD) ] || mkdir -p $(BUILD)
	@make --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

$(CHAIN):
	@make --no-print-directory -C $(CURDIR)/$(CHAIN) -f $(CURDIR)/$(CHAIN)/Makefile

# Holy crap this is an ugly hack
$(CHAIN_H): $(CHAIN)
	@xxd -u -i $(CHAIN)/$(CHAIN).bin > $(CHAIN)/$(CHAIN).h
	@sed 's/$(CHAIN)_$(CHAIN)/$(CHAIN)/g' $(CHAIN)/$(CHAIN).h > $(CHAIN_H)
	@rm -rf $(CHAIN)/$(CHAIN).h

#---------------------------------------------------------------------------------
clean:
	@make --no-print-directory -C $(CURDIR)/$(CHAIN) -f $(CURDIR)/$(CHAIN)/Makefile clean
	@rm -rf $(CURDIR)/$(SOURCES)/$(CHAIN).h $(BUILD) $(OUTPUT).bin
	@echo cleaned $(NAME)

#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
$(OUTPUT).bin	:	$(OUTPUT).elf
$(OUTPUT).elf	:	$(OFILES)

#---------------------------------------------------------------------------------
%.bin: %.elf
	@$(OBJCOPY) --set-section-flags .bss=alloc,load,contents -O binary $< $@
	@echo built $(NAME)
	@rm -f $(OUTPUT).elf

-include $(DEPENDS)


#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
