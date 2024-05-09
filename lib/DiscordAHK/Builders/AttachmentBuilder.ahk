Class AttachmentBuilder {
	/**
	 * new AttachmentBuilder()
	 * @param File relative path to file
	 */
	__New(param) {
		this.fileName := "image.png", this.file := param
		loop files param
			this.file := A_LoopFileFullPath, this.fileName := A_LoopFileName
		this.attachmentName := "attachment://" this.fileName
	}
}