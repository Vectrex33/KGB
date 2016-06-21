#include "common.h"

static FATFS nand_fs, sd_fs;

void error(char *err_msg)
{
    printf("ERROR: %s\nPress any key to power off", err_msg);
	wait_for_key();
	ctr_system_poweroff();
}

void main()
{
    // Initialize console output
	console_init();
	printf("KGB\n");

    if (N3DS)
    {
        printf("Setting slot0x05KeyY\n");
        if (set_nctrnand_key() != 0)
            error("N3DS key 0x05 could not be set");
    }

    // Initialize IO interfaces
    ctr_nand_interface nand_io;
    ctr_nand_crypto_interface ctr_io;
    ctr_sd_interface sd_io;

    ctr_fatfs_initialize(&nand_io, &ctr_io, NULL, &sd_io);
    ctr_fatfs_default_setup(&ctr_io, NULL, &sd_io);

    // Attempt to mount FAT filesystems
    FRESULT f_ret;
    f_ret = f_mount(&nand_fs, "0:", 0);
    if (f_ret != 0)
    {
        printf("CTRNAND f_mount returned ");
        print_fresult(f_ret);
    }

    if (f_ret != FR_OK)
    {
        printf("Failed to mount CTRNAND... press a key to reboot\n");
        wait_for_key();
        ctr_system_reset();
    }
    
    //dump_firm0();

    // Attempt to load FIRM from CTRNAND
    s32 ret = load_firm();
    if (ret != 0)
        printf("load_firm returned %d\n", ret);

	if (ret != 0)
		error("couldn't load firmware");

    // Unmount CTRNAND
    f_ret = f_mount(NULL, "0:", 0);
    if (f_ret != 0)
    {
        printf("f_(un)mount returned ");
        print_fresult(f_ret);
    }

    // Destroy IO interfaces
    ctr_nand_crypto_interface_destroy(&ctr_io);
    ctr_nand_interface_destroy(&nand_io);
    ctr_sd_interface_destroy(&sd_io);

    // TODO: Add support for loading an ARM9 payload off of CTRNAND/SD (if inserted)
	printf("Press:\n[A] to boot\n[B] to power off\n"/*[Y] load arm9loaderhax.bin from CTRNAND\n*/"%s\n", SD_INSERTED ? /*"[X] load arm9loaderhax.bin from SD\n"*/ "" : "");

	u32 key;

	while(1)
	{
		key = wait_for_key();

		if (key & KEY_A)
		{
			printf("Booting FIRM\n");
			launch_firm();
		}

		else if (key & KEY_B)
			ctr_system_poweroff();

        else if (key & KEY_Y)
            chainload("CTRNAND:/arm9loaderhax.bin");

        else if ((key & KEY_X) && SD_INSERTED)
        {
            f_ret = f_mount(&sd_fs, "SD:", 0);
            if (f_ret != FR_OK)
            {
                printf("f_mount returned ");
                print_fresult(f_ret);
                error("couldn't mount SD card");
            }

            chainload("SD:/arm9loaderhax.bin");
        }
	}
}

void chainload(const char *payload_path)
{
    // Stubbed
    printf("not yet implemented: %s\n", payload_path);
    return;
}

void print_fresult(FRESULT f_ret)
{ // because I got bored of seeing numbers and consulting the manual
    printf("FR_");
    switch(f_ret)
    {
        case FR_OK:
            printf("OK");
            break;
        case FR_DISK_ERR:
            printf("DISK_ERR");
            break;
        case FR_INT_ERR:
            printf("INT_ERR");
            break;
        case FR_NOT_READY:
            printf("NOT_READY");
            break;
        case FR_NO_FILE:
            printf("NO_FILE");
            break;
        case FR_NO_PATH:
            printf("NO_PATH");
            break;
        case FR_INVALID_NAME:
            printf("INVALID_NAME");
            break;
        case FR_DENIED:
            printf("DENIED");
            break;
        case FR_EXIST:
            printf("EXIST");
            break;
        case FR_INVALID_OBJECT:
            printf("INVALID_OBJECT");
            break;
        case FR_WRITE_PROTECTED:
            printf("WRITE_PROTECTED");
            break;
        case FR_INVALID_DRIVE:
            printf("INVALID_DRIVE");
            break;
        case FR_NOT_ENABLED:
            printf("NOT_ENABLED");
            break;
        case FR_NO_FILESYSTEM:
            printf("NO_FILESYSTEM");
            break;
        case FR_TIMEOUT:
            printf("TIMEOUT");
            break;
        case FR_LOCKED:
            printf("LOCKED");
            break;
        case FR_NOT_ENOUGH_CORE:
            printf("NOT_ENOUGH_CORE");
            break;
        case FR_TOO_MANY_OPEN_FILES:
            printf("TOO_MANY_OPEN_FILES");
            break;

        default: // This should never happen
            printf("U_NUTS");
            break;
    }

    printf("\n");
    return;
}
