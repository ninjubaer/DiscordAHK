Class AttachmentBuilder {
	/**
	 * new AttachmentBuilder()
	 * @param File relative path to file
	 */
	__New(param) {
		if !FileExist(param)
			try Integer(param)
			catch 
				Throw Error("AttachmentBuilder: File does not exist",,param)
		this.fileName := "image.png", this.file := param, this.isBitmap := 1
		loop files param
			this.file := A_LoopFileFullPath, this.fileName := A_LoopFileName, this.isBitmap := 0
		this.attachmentName := "attachment://" this.fileName, this.contentType := this.isBitmap ? "image/png" : Discord.MimeType(this.fileName)
	}
}