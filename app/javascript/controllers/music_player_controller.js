import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "audio",
    "playIcon",
    "pauseIcon",
    "currentTime",
    "totalTime",
    "progress",
    "progressBar",
    "songTitle",
    "artistName",
    "artistLink",
    "searchInput",
    "songList",
  ]

  connect() {
    this.songs = []
    this.currentSongIndex = 0
    this.audioTarget.volume = 0.25

    // Load songs
    this.loadSongs()

    // Set up audio event listeners
    this.audioTarget.addEventListener('timeupdate', () => this.updateProgress())
    this.audioTarget.addEventListener('ended', () => this.handleSongEnd())
    this.audioTarget.addEventListener('loadedmetadata', () => this.updateDuration())
  }

  async loadSongs() {
    try {
      const response = await fetch('/music_player.json')
      this.songs = await response.json()
      this.renderSongList()
    } catch (error) {
      console.error('Failed to load songs:', error)
    }
  }

  openModal() {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  closeModal() {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  togglePlay() {
    if (!this.audioTarget.src) {
      this.loadSong(this.songs[this.currentSongIndex])
    }

    if (this.audioTarget.paused) {
      this.audioTarget.play()
      this.playIconTarget.classList.add('hidden')
      this.pauseIconTarget.classList.remove('hidden')
    } else {
      this.audioTarget.pause()
      this.playIconTarget.classList.remove('hidden')
      this.pauseIconTarget.classList.add('hidden')
    }
  }

  playNow(event) {
    const songId = parseInt(event.currentTarget.dataset.songId)
    const song = this.songs.find(s => s.id === songId)
    if (song) {
      this.loadAndPlaySong(song)
    }
  }

  nextSong() {
    this.currentSongIndex = (this.currentSongIndex + 1) % this.songs.length
    this.loadAndPlaySong(this.songs[this.currentSongIndex])
  }

  previousSong() {
    this.currentSongIndex = (this.currentSongIndex - 1) % this.songs.length
    this.loadAndPlaySong(this.songs[this.currentSongIndex])
  }

  seek(event) {
    const rect = this.progressBarTarget.getBoundingClientRect()
    const percent = (event.clientX - rect.left) / rect.width
    this.audioTarget.currentTime = percent * this.audioTarget.duration
  }

  search() {
    this.renderSongList()
  }

  loadSong(song) {
    this.audioTarget.src = song.file

    this.songTitleTarget.textContent = song.title
    this.artistNameTarget.textContent = song.artist
    this.artistLinkTarget.href = song.credit_url

    this.currentSongIndex = this.songs.findIndex(s => s.id === song.id)
  }

  loadAndPlaySong(song) {
    this.loadSong(song)
    this.playIconTarget.classList.add('hidden')
    this.pauseIconTarget.classList.remove('hidden')
    this.audioTarget.play()
  }

  handleSongEnd() {
    if (!this.isLooping) {
      this.nextSong()
    }
  }

  updateProgress() {
    const current = this.audioTarget.currentTime
    const duration = this.audioTarget.duration

    if (!isNaN(duration)) {
      this.currentTimeTarget.textContent = this.formatTime(current)
      const percent = (current / duration) * 100
      this.progressTarget.style.width = `${percent}%`
    }
  }

  updateDuration() {
    if (!isNaN(this.audioTarget.duration)) {
      this.totalTimeTarget.textContent = this.formatTime(this.audioTarget.duration)
    }
  }

  formatTime(seconds) {
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  renderSongList() {
    const searchTerm = this.searchInputTarget.value.toLowerCase()
    const filteredSongs = this.songs.filter(song =>
      song.title.toLowerCase().includes(searchTerm) ||
      song.artist.toLowerCase().includes(searchTerm)
    )

    this.songListTarget.innerHTML = filteredSongs.map(song => `
      <div class="song-item">
        <div class="song-info">
          <div class="song-title">${song.title}</div>
          <div class="song-artist">${song.artist}</div>
        </div>
        <div class="song-duration">${this.formatTime(song.duration)}</div>
        <div class="song-actions">
          <button 
            class="song-action-btn play-btn"
            data-song-id="${song.id}"
            data-action="click->music-player#playNow"
            title="Play now">
            ▶️
          </button>
        </div>
      </div>
    `).join('')
  }
}